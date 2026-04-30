/**
 * paymentController.js
 * Controller xử lý luồng thanh toán VNPay:
 *   POST /api/payment/create     → Tạo URL thanh toán
 *   GET  /api/payment/vnpay-return → Xử lý return URL (deep link về app)
 *   POST /api/payment/vnpay-ipn   → IPN server-to-server từ VNPay
 */

const { createPaymentUrl, verifyCallback } = require('./vnpayService');
const db = require('../../config/db');

const PaymentController = {

    /**
     * POST /api/payment/create
     * Body: { maDonHang, tongTien, bankCode? }
     * Trả về: { success, payUrl, txnRef }
     */
    createPayment: async (req, res, next) => {
        try {
            const { maDonHang, tongTien, bankCode } = req.body;

            if (!maDonHang || !tongTien) {
                return res.status(400).json({ success: false, message: 'Thiếu maDonHang hoặc tongTien' });
            }

            // Kiểm tra đơn hàng tồn tại và thuộc về user
            const [order] = await db.query(
                'SELECT maDonHang, tongTien, trangThaiDonHang FROM donhang WHERE maDonHang = ? AND maTaiKhoan = ?',
                [maDonHang, req.user.maTaiKhoan]
            );

            if (!order) {
                return res.status(404).json({ success: false, message: 'Đơn hàng không tồn tại' });
            }

            // Lấy IP client
            const clientIp =
                req.headers['x-forwarded-for']?.split(',')[0]?.trim() ||
                req.socket?.remoteAddress ||
                '127.0.0.1';

            const { payUrl, txnRef } = createPaymentUrl({
                orderId: maDonHang,
                amount: Math.round(tongTien),
                orderInfo: `Thanh toan don hang #${maDonHang}`,
                clientIp,
                bankCode: bankCode || '',
            });

            // Lưu txnRef vào DB để đối chiếu sau
            await db.query(
                `INSERT INTO thanhtoan (maDonHang, txnRef, soTien, trangThai, thoiGianTao)
                 VALUES (?, ?, ?, 'pending', NOW())
                 ON DUPLICATE KEY UPDATE txnRef = VALUES(txnRef), thoiGianTao = NOW()`,
                [maDonHang, txnRef, Math.round(tongTien)]
            );

            return res.json({ success: true, payUrl, txnRef });
        } catch (error) {
            next(error);
        }
    },

    /**
     * GET /api/payment/vnpay-return
     * VNPay redirect về đây sau khi thanh toán.
     * Sau đó redirect về deep link của app.
     */
    returnUrl: async (req, res, next) => {
        try {
            const result = verifyCallback(req.query);

            // Cập nhật trạng thái đơn hàng
            if (result.isValid && result.orderId) {
                const newStatus = result.success ? 'daThanhToan' : 'thanhToanThatBai';
                await db.query(
                    `UPDATE donhang SET phuongThucThanhToan = 'VNPAY', trangThaiThanhToan = ?
                     WHERE maDonHang = ?`,
                    [newStatus === 'daThanhToan' ? 'paid' : 'failed', result.orderId]
                );

                await db.query(
                    `UPDATE thanhtoan SET trangThai = ?, maGiaoDich = ?, thoiGianHoanTat = NOW()
                     WHERE maDonHang = ? AND txnRef = ?`,
                    [result.success ? 'success' : 'failed',
                     req.query['vnp_TransactionNo'] || '',
                     result.orderId, result.txnRef]
                );
            }

            // Deep link về app Flutter
            const appScheme = process.env.APP_SCHEME || 'shipfood';
            const deepLink = result.success
                ? `${appScheme}://payment/success?orderId=${result.orderId}&message=${encodeURIComponent(result.message)}`
                : `${appScheme}://payment/failed?orderId=${result.orderId}&message=${encodeURIComponent(result.message)}&code=${result.responseCode}`;

            // Redirect về app
            return res.redirect(deepLink);
        } catch (error) {
            next(error);
        }
    },

    /**
     * POST /api/payment/vnpay-ipn
     * VNPay gọi server-to-server khi giao dịch hoàn tất.
     * Phải trả về { RspCode: '00', Message: 'Confirm Success' }
     */
    ipnHandler: async (req, res, next) => {
        try {
            const result = verifyCallback(req.query);

            if (!result.isValid) {
                return res.json({ RspCode: '97', Message: 'Invalid Checksum' });
            }

            // Kiểm tra đơn hàng
            const [payment] = await db.query(
                'SELECT * FROM thanhtoan WHERE txnRef = ?',
                [result.txnRef]
            );

            if (!payment) {
                return res.json({ RspCode: '01', Message: 'Order not found' });
            }

            if (payment.trangThai === 'success') {
                return res.json({ RspCode: '02', Message: 'Order already confirmed' });
            }

            // Kiểm tra số tiền
            if (payment.soTien !== result.amount) {
                return res.json({ RspCode: '04', Message: 'Invalid Amount' });
            }

            // Cập nhật DB
            if (result.success) {
                await db.query(
                    `UPDATE donhang SET trangThaiThanhToan = 'paid', phuongThucThanhToan = 'VNPAY'
                     WHERE maDonHang = ?`,
                    [result.orderId]
                );
            }

            await db.query(
                `UPDATE thanhtoan SET trangThai = ?, maGiaoDich = ?, thoiGianHoanTat = NOW()
                 WHERE txnRef = ?`,
                [result.success ? 'success' : 'failed',
                 req.query['vnp_TransactionNo'] || '',
                 result.txnRef]
            );

            return res.json({ RspCode: '00', Message: 'Confirm Success' });
        } catch (error) {
            console.error('[IPN Error]', error);
            return res.json({ RspCode: '99', Message: 'Unknown Error' });
        }
    },

    /**
     * GET /api/payment/status/:maDonHang
     * Kiểm tra trạng thái thanh toán của đơn hàng.
     */
    getStatus: async (req, res, next) => {
        try {
            const { maDonHang } = req.params;
            const [payment] = await db.query(
                `SELECT tt.trangThai, tt.soTien, tt.thoiGianHoanTat, tt.maGiaoDich,
                        d.trangThaiThanhToan
                 FROM thanhtoan tt
                 JOIN donhang d ON d.maDonHang = tt.maDonHang
                 WHERE tt.maDonHang = ? AND d.maTaiKhoan = ?
                 ORDER BY tt.thoiGianTao DESC LIMIT 1`,
                [maDonHang, req.user.maTaiKhoan]
            );

            if (!payment) {
                return res.json({ success: true, data: { trangThai: 'not_found' } });
            }

            return res.json({ success: true, data: payment });
        } catch (error) {
            next(error);
        }
    },
    /**
     * POST /api/payment/refund
     * Body: { maDonHang }
     */
    refundPayment: async (req, res, next) => {
        try {
            const { maDonHang } = req.body;
            const maTaiKhoan = req.user.maTaiKhoan;

            // 1. Kiểm tra đơn hàng có thể hoàn tiền không
            const [order] = await db.query(
                `SELECT * FROM donhang 
                 WHERE maDonHang = ? AND maTaiKhoan = ? 
                   AND trangThaiThanhToan = 'paid' 
                   AND trangThaiDonHang IN ('choGhepDon', 'choXacNhan')`,
                [maDonHang, maTaiKhoan]
            );

            if (!order) {
                return res.status(400).json({ 
                    success: false, 
                    message: 'Đơn hàng không đủ điều kiện hoàn tiền (phải là đơn đã thanh toán và chưa được chuẩn bị).' 
                });
            }

            // 2. Thực hiện hoàn tiền (Giả lập cho môi trường Test/Sandbox)
            // Trong môi trường Production, bước này sẽ gọi API VNPay Refund
            
            // 3. Cập nhật DB
            await db.query(
                "UPDATE donhang SET trangThaiDonHang = 'daHuy', trangThaiThanhToan = 'refunded' WHERE maDonHang = ?",
                [maDonHang]
            );
            
            await db.query(
                "UPDATE thanhtoan SET trangThai = 'refunded', thoiGianHoanTat = NOW() WHERE maDonHang = ?",
                [maDonHang]
            );

            return res.json({ 
                success: true, 
                message: 'Yêu cầu hoàn tiền đã được xử lý thành công. Tiền sẽ được hoàn lại vào tài khoản của bạn trong 3-5 ngày làm việc.' 
            });
        } catch (error) {
            next(error);
        }
    },
};

module.exports = PaymentController;

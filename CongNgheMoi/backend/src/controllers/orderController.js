const OrderModel = require('../models/orderModel');

const OrderController = {
    // 1. Đặt hàng (Checkout) - Không dùng GPS
    checkout: async (req, res, next) => {
        try {
            const maTaiKhoan = req.user.maTaiKhoan;
            const { maToaNha, maPhong, items, tongTien } = req.body;

            if (!maToaNha || !maPhong) {
                return res.status(400).json({ success: false, message: 'Vui lòng điền đầy đủ Tòa nhà và Phòng!' });
            }

            if (!items || items.length === 0) {
                return res.status(400).json({ success: false, message: 'Giỏ hàng trống!' });
            }

            const newOrderId = await OrderModel.createOrder({
                maTaiKhoan, maToaNha, maPhong, items, tongTien
            });

            res.status(201).json({
                success: true,
                message: 'Đặt hàng thành công! Đơn đang trong trạng thái chờ ghép.',
                data: { maDonHang: newOrderId, maToaNha }
            });
        } catch (error) {
            next(error);
        }
    },

    // 2. Lấy đơn đang chờ trong cùng khu vực (hiển thị cho khách sau khi đặt)
    getAreaOrders: async (req, res, next) => {
        try {
            const { maToaNha } = req.query;
            if (!maToaNha) {
                return res.status(400).json({ success: false, message: 'Thiếu maToaNha.' });
            }
            const orders = await OrderModel.getAreaOrders(maToaNha);
            res.status(200).json({ success: true, data: orders });
        } catch (error) {
            next(error);
        }
    },

    // 3. Lịch sử đơn của user hiện tại
    getMyOrders: async (req, res, next) => {
        try {
            const orders = await OrderModel.getMyOrders(req.user.maTaiKhoan);
            res.status(200).json({ success: true, data: orders });
        } catch (error) {
            next(error);
        }
    },

    // 4. Nhân viên đánh dấu đơn đã xong (dùng chung cho staff)
    markOrderReady: async (req, res, next) => {
        try {
            const maDonHang = Number(req.params.id);
            const updated = await OrderModel.markOrderReady(maDonHang);

            if (!updated) {
                return res.status(400).json({ success: false, message: 'Đơn không tồn tại hoặc không ở trạng thái chuẩn bị.' });
            }

            // Kiểm tra nếu toàn bộ đơn trong nhóm đã xong → chuyển nhóm sang 'dangGiao'
            await OrderModel.checkAndUpdateGroup(maDonHang);

            res.status(200).json({ success: true, message: 'Đã đánh dấu đơn hoàn thành!' });
        } catch (error) {
            next(error);
        }
    },

    // 5. Nhân viên lấy danh sách đơn cần chuẩn bị
    getStaffOrders: async (req, res, next) => {
        try {
            // Lấy maGianHang từ thông tin nhân viên
            const db = require('../config/db');
            const rows = await db.query(
                'SELECT maGianHang FROM gianhang WHERE maTaiKhoan = ?',
                [req.user.maTaiKhoan]
            );
            if (!rows[0]) {
                return res.status(404).json({ success: false, message: 'Không tìm thấy gian hàng.' });
            }
            const maGianHang = rows[0].maGianHang;
            const orders = await OrderModel.getOrdersForStaff(maGianHang);
            res.status(200).json({ success: true, data: orders });
        } catch (error) {
            next(error);
        }
    },
    // 6. Khách hàng hủy đơn (chỉ cho phép ở trạng thái choGhepDon)
    cancelOrder: async (req, res, next) => {
        try {
            const maTaiKhoan = req.user.maTaiKhoan;
            const maDonHang = Number(req.params.id);

            const db = require('../config/db');
            const rows = await db.query(
                'SELECT * FROM donhang WHERE maDonHang = ? AND maTaiKhoan = ?',
                [maDonHang, maTaiKhoan]
            );

            if (!rows[0]) {
                return res.status(404).json({ success: false, message: 'Không tìm thấy đơn hàng.' });
            }
            if (rows[0].trangThaiDonHang !== 'choGhepDon') {
                return res.status(400).json({ success: false, message: 'Chỉ có thể hủy đơn đang chờ ghép.' });
            }

            await db.query(
                "UPDATE donhang SET trangThaiDonHang = 'daHuy' WHERE maDonHang = ?",
                [maDonHang]
            );

            res.status(200).json({ success: true, message: 'Đã hủy đơn hàng thành công.' });
        } catch (error) {
            next(error);
        }
    },

    // Nhân viên nhấn bắt đầu làm (chuyển từ choXacNhan sang dangChuanBi)
    startPreparing: async (req, res, next) => {
        try {
            const maDonHang = Number(req.params.id);
            const db = require('../config/db');
            const rows = await db.query(
                'SELECT maGianHang FROM gianhang WHERE maTaiKhoan = ?',
                [req.user.maTaiKhoan]
            );
            if (!rows[0]) {
                return res.status(404).json({ success: false, message: 'Không tìm thấy gian hàng.' });
            }
            const maGianHang = rows[0].maGianHang;

            const updated = await OrderModel.startPreparingOrder(maDonHang, maGianHang);
            if (updated) {
                res.status(200).json({ success: true, message: 'Đã chuyển đơn sang trạng thái Đang chuẩn bị.' });
            } else {
                res.status(400).json({ success: false, message: 'Đơn hàng không tồn tại hoặc đã được xử lý.' });
            }
        } catch (error) {
            next(error);
        }
    },

    // ============ KITCHEN DISPLAY SYSTEM ============

    // 7. Lấy danh sách gom món KDS cho gian hàng
    getStaffKDS: async (req, res, next) => {
        try {
            const db = require('../config/db');
            const rows = await db.query(
                'SELECT maGianHang FROM gianhang WHERE maTaiKhoan = ?',
                [req.user.maTaiKhoan]
            );
            if (!rows[0]) {
                return res.status(404).json({ success: false, message: 'Không tìm thấy gian hàng.' });
            }
            const maGianHang = rows[0].maGianHang;
            const data = await OrderModel.getKDSData(maGianHang);
            res.status(200).json({ success: true, data });
        } catch (error) {
            next(error);
        }
    },

    // 8. Quẹt đánh dấu món KDS đã xong
    swipeKDSItem: async (req, res, next) => {
        try {
            const maMonAn = Number(req.params.dishId);
            const db = require('../config/db');
            const rows = await db.query(
                'SELECT maGianHang FROM gianhang WHERE maTaiKhoan = ?',
                [req.user.maTaiKhoan]
            );
            if (!rows[0]) {
                return res.status(404).json({ success: false, message: 'Không tìm thấy gian hàng.' });
            }
            const maGianHang = rows[0].maGianHang;

            const updated = await OrderModel.markKDSItemReady(maGianHang, maMonAn);
            
            res.status(200).json({ 
                success: true, 
                message: updated ? 'Đã đánh dấu nấu xong.' : 'Không có món nào cần cập nhật.' 
            });
        } catch (error) {
            next(error);
        }
    },
    
    // 9. Thống kê
    getStatistics: async (req, res, next) => {
        try {
            console.log('GET STATISTICS CALLED FOR:', req.user.maTaiKhoan, req.query);
            const { period, date } = req.query;
            const db = require('../config/db');
            const rows = await db.query(
                'SELECT maGianHang FROM gianhang WHERE maTaiKhoan = ?',
                [req.user.maTaiKhoan]
            );
            if (!rows[0]) {
                return res.status(404).json({ success: false, message: 'Không tìm thấy gian hàng.' });
            }
            const maGianHang = rows[0].maGianHang;

            const data = await OrderModel.getStatistics(maGianHang, period, date);
            res.status(200).json({ success: true, data });
        } catch (error) {
            next(error);
        }
    },

    // ══════════════════════════════════════════════════════════════════
    // DELIVERY TRIP (Tab Ship)
    // ══════════════════════════════════════════════════════════════════

    /** GET /api/orders/staff-ready-items — Lấy danh sách món đang ready chờ giao */
    getReadyItems: async (req, res, next) => {
        try {
            const db = require('../config/db');
            const rows = await db.query('SELECT maGianHang FROM gianhang WHERE maTaiKhoan = ?', [req.user.maTaiKhoan]);
            if (!rows[0]) return res.status(404).json({ success: false, message: 'Không tìm thấy gian hàng.' });
            const maGianHang = rows[0].maGianHang;

            const items = await db.query(`
                SELECT ct.maChiTiet, ct.maMonAn, ct.maDonHang, ct.trangThaiMon,
                       m.tenMonAn, m.hinhAnh,
                       d.maToaNha, d.maPhong,
                       tn.tenToaNha, p.tenPhong,
                       tk.hoTen AS tenKhach
                FROM chitietdonhang ct
                JOIN monan m ON ct.maMonAn = m.maMonAn
                JOIN donhang d ON ct.maDonHang = d.maDonHang
                JOIN taikhoan tk ON d.maTaiKhoan = tk.maTaiKhoan
                LEFT JOIN toanha tn ON d.maToaNha = tn.maToaNha
                LEFT JOIN phong p ON d.maPhong = p.maPhong
                WHERE m.maGianHang = ? AND ct.trangThaiMon = 'ready'
                ORDER BY tn.tenToaNha, p.tenPhong
            `, [maGianHang]);

            res.json({ success: true, data: items });
        } catch (error) { next(error); }
    },

    /** POST /api/orders/staff-start-trip — Gom tất cả món ready thành 1 chuyến giao */
    startDeliveryTrip: async (req, res, next) => {
        try {
            const db = require('../config/db');
            const rows = await db.query('SELECT maGianHang FROM gianhang WHERE maTaiKhoan = ?', [req.user.maTaiKhoan]);
            if (!rows[0]) return res.status(404).json({ success: false, message: 'Không tìm thấy gian hàng.' });
            const maGianHang = rows[0].maGianHang;

            // Lấy tất cả maChiTiet đang ready
            const readyItems = await db.query(`
                SELECT ct.maChiTiet, ct.maDonHang
                FROM chitietdonhang ct
                JOIN monan m ON ct.maMonAn = m.maMonAn
                WHERE m.maGianHang = ? AND ct.trangThaiMon = 'ready'
            `, [maGianHang]);

            if (readyItems.length === 0)
                return res.status(400).json({ success: false, message: 'Không có món nào đang chờ giao.' });

            // Tạo chuyến giao mới trong nhomgiaohang
            const [tripResult] = await db.query(
                `INSERT INTO nhomgiaohang (maToaNha, thoiGianTaoNhom, trangThaiNhom) VALUES (?, NOW(), 'dangGiao')`,
                [null]
            );
            const maNhomGiaoHang = tripResult.insertId;

            // Cập nhật trangThaiMon = 'delivering' + gán maNhomGiaoHang vào chitietdonhang
            const chiTietIds = readyItems.map(r => r.maChiTiet);
            await db.query(
                `UPDATE chitietdonhang SET trangThaiMon = 'delivering', maNhomGiaoHang = ? WHERE maChiTiet IN (?)`,
                [maNhomGiaoHang, chiTietIds]
            );

            // Đồng bộ trạng thái donhang: nếu có món đang delivering → dangGiao
            const donHangIds = [...new Set(readyItems.map(r => r.maDonHang))];
            if (donHangIds.length > 0) {
                await db.query(
                    `UPDATE donhang SET trangThaiDonHang = 'dangGiao'
                     WHERE maDonHang IN (?) AND trangThaiDonHang NOT IN ('daGiao', 'daHuy')`,
                    [donHangIds]
                );
            }

            res.json({ success: true, message: `Đã bắt đầu chuyến giao với ${readyItems.length} phần ăn!`, data: { maNhomGiaoHang, soMon: readyItems.length } });
        } catch (error) { next(error); }
    },

    /** PUT /api/orders/staff-complete-trip/:tripId — Hoàn tất chuyến giao */
    completeTrip: async (req, res, next) => {
        try {
            const maNhomGiaoHang = Number(req.params.tripId);
            const db = require('../config/db');

            // Lấy danh sách maChiTiet và maDonHang trong chuyến này
            const items = await db.query(
                `SELECT maChiTiet, maDonHang FROM chitietdonhang WHERE maNhomGiaoHang = ? AND trangThaiMon = 'delivering'`,
                [maNhomGiaoHang]
            );

            if (items.length === 0)
                return res.status(400).json({ success: false, message: 'Chuyến không tồn tại hoặc đã hoàn tất.' });

            const chiTietIds = items.map(r => r.maChiTiet);
            const donHangIds = [...new Set(items.map(r => r.maDonHang))];

            // Đánh dấu các món là delivered
            await db.query(
                `UPDATE chitietdonhang SET trangThaiMon = 'delivered' WHERE maChiTiet IN (?)`,
                [chiTietIds]
            );

            // Đồng bộ donhang: nếu TẤT CẢ món của đơn đều delivered → daGiao
            for (const maDonHang of donHangIds) {
                const [check] = await db.query(
                    `SELECT COUNT(*) AS chua_xong FROM chitietdonhang
                     WHERE maDonHang = ? AND trangThaiMon NOT IN ('delivered', 'cancelled')`,
                    [maDonHang]
                );
                if ((check[0]?.chua_xong ?? check?.chua_xong ?? 0) == 0) {
                    await db.query(
                        `UPDATE donhang SET trangThaiDonHang = 'daGiao' WHERE maDonHang = ?`,
                        [maDonHang]
                    );
                }
            }

            // Đóng chuyến
            await db.query(`UPDATE nhomgiaohang SET trangThaiNhom = 'daHoanThanh' WHERE maNhomGiaoHang = ?`, [maNhomGiaoHang]);

            res.json({ success: true, message: 'Hoàn tất chuyến giao hàng! 🎉' });
        } catch (error) { next(error); }
    },

    /** GET /api/orders/staff-active-trip — Chuyến đang giao hiện tại */
    getActiveTrip: async (req, res, next) => {
        try {
            const db = require('../config/db');
            const rows = await db.query('SELECT maGianHang FROM gianhang WHERE maTaiKhoan = ?', [req.user.maTaiKhoan]);
            if (!rows[0]) return res.status(404).json({ success: false, message: 'Không tìm thấy gian hàng.' });
            const maGianHang = rows[0].maGianHang;

            // Tìm chuyến đang giao có chứa món của gian hàng này
            const trips = await db.query(`
                SELECT DISTINCT ct.maNhomGiaoHang
                FROM chitietdonhang ct
                JOIN monan m ON ct.maMonAn = m.maMonAn
                JOIN nhomgiaohang ng ON ct.maNhomGiaoHang = ng.maNhomGiaoHang
                WHERE m.maGianHang = ? AND ct.trangThaiMon = 'delivering'
                  AND ng.trangThaiNhom = 'dangGiao'
                LIMIT 1
            `, [maGianHang]);

            if (trips.length === 0)
                return res.json({ success: true, data: null });

            const maNhomGiaoHang = trips[0].maNhomGiaoHang;

            const items = await db.query(`
                SELECT ct.maChiTiet, ct.maDonHang, ct.trangThaiMon,
                       m.tenMonAn, m.hinhAnh,
                       tn.tenToaNha, p.tenPhong,
                       tk.hoTen AS tenKhach
                FROM chitietdonhang ct
                JOIN monan m ON ct.maMonAn = m.maMonAn
                JOIN donhang d ON ct.maDonHang = d.maDonHang
                JOIN taikhoan tk ON d.maTaiKhoan = tk.maTaiKhoan
                LEFT JOIN toanha tn ON d.maToaNha = tn.maToaNha
                LEFT JOIN phong p ON d.maPhong = p.maPhong
                WHERE ct.maNhomGiaoHang = ? AND m.maGianHang = ?
                ORDER BY tn.tenToaNha, p.tenPhong
            `, [maNhomGiaoHang, maGianHang]);

            res.json({ success: true, data: { maNhomGiaoHang, items } });
        } catch (error) { next(error); }
    },
};

module.exports = OrderController;



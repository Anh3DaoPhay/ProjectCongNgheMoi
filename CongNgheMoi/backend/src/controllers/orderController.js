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
            const { period, date } = req.query; // period: day, month, year. date: YYYY-MM-DD
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
    }
};

module.exports = OrderController;


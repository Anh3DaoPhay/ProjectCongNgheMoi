const UserModel = require('../models/customerModel');

const UserController = {
    getProfile: async (req, res, next) => {
        try {
            const user = await UserModel.findById(req.user.maTaiKhoan);
            if (!user) return res.status(404).json({ success: false, message: 'Không tìm thấy người dùng' });
            
            // Map data to expected frontend keys
            const payload = {
                ...user,
                fullName: user.hoTen,
                name: user.tenDangNhap,
                email: user.email || '',
                phone: user.soDienThoai,
                avatarUrl: user.anhDaiDien ? (user.anhDaiDien.startsWith('http') ? user.anhDaiDien : `${req.protocol}://${req.get('host')}${user.anhDaiDien}`) : ''
            };

            res.status(200).json({ success: true, data: payload });
        } catch (error) { next(error); }
    },

    updateProfile: async (req, res, next) => {
        try {
            await UserModel.update(req.user.maTaiKhoan, req.body);
            res.status(200).json({ success: true, message: 'Cập nhật thông tin thành công!' });
        } catch (error) { next(error); }
    },

    uploadAvatar: async (req, res, next) => {
        try {
            if (!req.file) {
                return res.status(400).json({ success: false, message: 'Không tìm thấy file ảnh' });
            }

            const avatarUrl = `/img/anhdaidien/${req.file.filename}`;
            await UserModel.updateAvatar(req.user.maTaiKhoan, avatarUrl);

            res.status(200).json({ 
                success: true, 
                message: 'Tải ảnh đại diện thành công',
                avatarUrl: `${req.protocol}://${req.get('host')}${avatarUrl}`
            });
        } catch (error) { next(error); }
    }
};
module.exports = UserController;
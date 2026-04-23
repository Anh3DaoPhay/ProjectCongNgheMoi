// models/auth.model.js
const db = require('../config/db'); 

const AuthModel = {
    // Tìm tài khoản theo tên đăng nhập
    findByUsername: async (tenDangNhap) => {
        const rows = await db.query(
            'SELECT * FROM taiKhoan WHERE tenDangNhap = ?',
            [tenDangNhap]
        );
        return rows[0]; // Trả về user đầu tiên hoặc undefined
    },

    // Tìm tài khoản theo số điện thoại (dành cho quên mật khẩu)
    findByPhone: async (soDienThoai) => {
        const rows = await db.query(
            'SELECT * FROM taiKhoan WHERE soDienThoai = ?',
            [soDienThoai]
        );
        return rows[0];
    },

    // Tạo tài khoản mới (Mặc định maVaiTro = 1 là Khách hàng)
    createAccount: async (data) => {
        const { tenDangNhap, matKhauHash, hoTen, email, soDienThoai } = data;
        const result = await db.query(
            `INSERT INTO taiKhoan (maVaiTro, tenDangNhap, matKhau, hoTen, email, soDienThoai, trangThai) 
             VALUES (1, ?, ?, ?, ?, ?, 1)`,
            [tenDangNhap, matKhauHash, hoTen, email || null, soDienThoai]
        );
        return result.insertId;
    },

    // Cập nhật mật khẩu mới
    updatePassword: async (maTaiKhoan, matKhauHash) => {
        const result = await db.query(
            'UPDATE taiKhoan SET matKhau = ? WHERE maTaiKhoan = ?',
            [matKhauHash, maTaiKhoan]
        );
        return result.affectedRows > 0;
    }
};

module.exports = AuthModel;
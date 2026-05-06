// Script tạo tài khoản Admin đầu tiên
// Chạy: node task/create_admin.js

const bcrypt = require('bcrypt');
const path = require('path');

// Load db config
const db = require(path.join(__dirname, '../backend/src/config/db'));

async function createAdmin() {
  const username = 'admin';
  const password = 'Admin@123';
  const hoTen    = 'Quản trị viên';
  const email    = 'admin@fooddelivery.com';

  const hash = await bcrypt.hash(password, 10);

  try {
    await db.query(
      `INSERT INTO taikhoan (tenDangNhap, matKhau, hoTen, email, maVaiTro, trangThai)
       VALUES (?, ?, ?, ?, 3, 1)
       ON DUPLICATE KEY UPDATE maVaiTro = 3, trangThai = 1`,
      [username, hash, hoTen, email]
    );
    console.log('✅ Tài khoản Admin đã được tạo thành công!');
    console.log(`   Tên đăng nhập: ${username}`);
    console.log(`   Mật khẩu: ${password}`);
  } catch (e) {
    console.error('❌ Lỗi:', e.message);
  } finally {
    process.exit(0);
  }
}

createAdmin();

-- Script tạo tài khoản Admin (role = 3)
-- Chạy lệnh này một lần trong MySQL để tạo tài khoản admin đầu tiên

-- Tài khoản: admin / Password: Admin@123
-- (Password đã được hash bằng bcrypt)

INSERT INTO taikhoan (tenDangNhap, matKhau, hoTen, email, maVaiTro, trangThai)
VALUES (
  'admin',
  '$2b$10$YvQ7b4FdQ9K3WjX5H2eQEurPTM3hEhwnkAZl2E9fF2cRlNnJsH8qe',
  'Quản trị viên',
  'admin@fooddelivery.com',
  3,
  1
)
ON DUPLICATE KEY UPDATE maVaiTro = 3, trangThai = 1;

-- Mật khẩu: Admin@123
-- Lưu ý: Sau khi tạo, đăng nhập bằng tài khoản này để vào Admin Dashboard

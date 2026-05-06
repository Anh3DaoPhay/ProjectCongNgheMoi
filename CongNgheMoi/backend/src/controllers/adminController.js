// controllers/adminController.js
const { query } = require('../config/db');
const bcrypt = require('bcrypt');

// Tự động thêm cột trangThai vào bảng taikhoan và gianhang nếu chưa có
async function ensureAdminColumns() {
  await query(`ALTER TABLE taikhoan ADD COLUMN IF NOT EXISTS trangThai TINYINT(1) NOT NULL DEFAULT 1`).catch(() => {});
  await query(`ALTER TABLE gianhang ADD COLUMN IF NOT EXISTS trangThai TINYINT(1) NOT NULL DEFAULT 1`).catch(() => {});
  await query(`ALTER TABLE chitietdonhang ADD COLUMN IF NOT EXISTS maNhomGiaoHang INT NULL`).catch(() => {});
}
// Gọi ngay khi module được load
ensureAdminColumns();

const AdminController = {

  // ══════════════════════════════════════════════════════════════════
  // DASHBOARD
  // ══════════════════════════════════════════════════════════════════
  getDashboard: async (req, res, next) => {
    try {
      const [[stats]] = await Promise.all([
        query(`
          SELECT
            (SELECT COUNT(*) FROM taikhoan)                             AS tongTaiKhoan,
            (SELECT COUNT(*) FROM taikhoan WHERE maVaiTro = 1)          AS tongKhachHang,
            (SELECT COUNT(*) FROM taikhoan WHERE maVaiTro = 2)          AS tongNhanVien,
            (SELECT COUNT(*) FROM gianhang)                             AS tongGianHang,
            (SELECT COUNT(*) FROM donhang)                              AS tongDonHang,
            (SELECT COALESCE(SUM(tongTien),0) FROM donhang
              WHERE trangThaiDonHang IN ('daGiao','choGiaoHang'))       AS tongDoanhThu,
            (SELECT COUNT(*) FROM promotions WHERE is_active = TRUE)    AS tongVoucher
        `),
      ]);

      const recentOrders = await query(`
        SELECT d.maDonHang, tk.hoTen AS tenKhach,
               d.tongTien, d.trangThaiDonHang, d.thoiGianDat,
               tn.tenToaNha
        FROM donhang d
        JOIN taikhoan tk ON d.maTaiKhoan = tk.maTaiKhoan
        LEFT JOIN toanha tn ON d.maToaNha = tn.maToaNha
        ORDER BY d.thoiGianDat DESC LIMIT 10
      `);

      res.json({ success: true, data: { stats: stats[0] ?? stats, recentOrders } });
    } catch (err) { next(err); }
  },

  // ══════════════════════════════════════════════════════════════════
  // QUẢN LÝ GIAN HÀNG (CĂNT IN)
  // ══════════════════════════════════════════════════════════════════

  /** GET /api/admin/stores */
  getStores: async (req, res, next) => {
    try {
      const rows = await query(`
        SELECT g.maGianHang, g.tenGianHang, g.moTa, g.hinhAnh,
               g.trangThai,
               tk.hoTen AS tenChuQuan, tk.email, tk.maTaiKhoan,
               COUNT(DISTINCT d.maDonHang) AS tongDon,
               COALESCE(SUM(CASE WHEN d.trangThaiDonHang IN ('daGiao','choGiaoHang') THEN d.tongTien ELSE 0 END),0) AS doanhThu
        FROM gianhang g
        LEFT JOIN taikhoan tk ON g.maTaiKhoan = tk.maTaiKhoan
        LEFT JOIN chitietdonhang ct ON ct.maMonAn IN (SELECT maMonAn FROM monan WHERE maGianHang = g.maGianHang)
        LEFT JOIN donhang d ON d.maDonHang = ct.maDonHang
        GROUP BY g.maGianHang
        ORDER BY g.maGianHang DESC
      `);
      res.json({ success: true, data: rows });
    } catch (err) { next(err); }
  },

  /** POST /api/admin/stores — Tạo gian hàng mới + tài khoản staff */
  createStore: async (req, res, next) => {
    try {
      const { tenGianHang, moTa, tenDangNhap, matKhau, hoTen, email, soDienThoai } = req.body;
      if (!tenGianHang || !tenDangNhap || !matKhau)
        return res.status(400).json({ success: false, message: 'Thiếu thông tin bắt buộc.' });

      // Tạo tài khoản nhân viên (role 2)
      const hash = await bcrypt.hash(matKhau, 10);
      const [accResult] = await query(
        `INSERT INTO taikhoan (tenDangNhap, matKhau, hoTen, email, soDienThoai, maVaiTro, trangThai)
         VALUES (?, ?, ?, ?, ?, 2, 1)`,
        [tenDangNhap, hash, hoTen || tenDangNhap, email || null, soDienThoai || null]
      );
      const maTaiKhoan = accResult.insertId;

      // Tạo gian hàng liên kết với tài khoản đó
      const [storeResult] = await query(
        `INSERT INTO gianhang (tenGianHang, moTa, maTaiKhoan, trangThai) VALUES (?, ?, ?, 1)`,
        [tenGianHang, moTa || '', maTaiKhoan]
      );

      res.status(201).json({ success: true, message: 'Tạo gian hàng thành công!', data: { maGianHang: storeResult.insertId, maTaiKhoan } });
    } catch (err) {
      if (err.code === 'ER_DUP_ENTRY')
        return res.status(400).json({ success: false, message: 'Tên đăng nhập đã tồn tại.' });
      next(err);
    }
  },

  /** PUT /api/admin/stores/:id — Cập nhật thông tin / Khóa-mở gian hàng */
  updateStore: async (req, res, next) => {
    try {
      const { id } = req.params;
      const { tenGianHang, moTa, trangThai } = req.body;
      await query(
        `UPDATE gianhang SET tenGianHang = COALESCE(?, tenGianHang),
                              moTa        = COALESCE(?, moTa),
                              trangThai   = COALESCE(?, trangThai)
         WHERE maGianHang = ?`,
        [tenGianHang ?? null, moTa ?? null, trangThai ?? null, id]
      );
      res.json({ success: true, message: 'Cập nhật gian hàng thành công!' });
    } catch (err) { next(err); }
  },

  // ══════════════════════════════════════════════════════════════════
  // QUẢN LÝ TÀI KHOẢN
  // ══════════════════════════════════════════════════════════════════

  /** GET /api/admin/users?role=1 */
  getUsers: async (req, res, next) => {
    try {
      const { role } = req.query;
      const rows = await query(
        `SELECT maTaiKhoan, tenDangNhap, hoTen, email, soDienThoai,
                maVaiTro, trangThai, ngayTao
         FROM taikhoan
         WHERE (? IS NULL OR maVaiTro = ?)
         ORDER BY maTaiKhoan DESC`,
        [role ?? null, role ?? null]
      );
      res.json({ success: true, data: rows });
    } catch (err) { next(err); }
  },

  /** PUT /api/admin/users/:id — Cập nhật thông tin / Phân quyền / Khóa-mở tài khoản */
  updateUser: async (req, res, next) => {
    try {
      const { id } = req.params;
      const { hoTen, email, maVaiTro, trangThai } = req.body;
      await query(
        `UPDATE taikhoan
         SET hoTen    = COALESCE(?, hoTen),
             email    = COALESCE(?, email),
             maVaiTro = COALESCE(?, maVaiTro),
             trangThai= COALESCE(?, trangThai)
         WHERE maTaiKhoan = ?`,
        [hoTen ?? null, email ?? null, maVaiTro ?? null, trangThai ?? null, id]
      );
      res.json({ success: true, message: 'Cập nhật tài khoản thành công!' });
    } catch (err) { next(err); }
  },

  // ══════════════════════════════════════════════════════════════════
  // QUẢN LÝ VOUCHER (TOÀN SÀN)
  // ══════════════════════════════════════════════════════════════════

  /** GET /api/admin/vouchers */
  getVouchers: async (req, res, next) => {
    try {
      const rows = await query(`
        SELECT p.id, p.code, p.title, p.description,
               p.discount_percent AS discountPercent,
               p.max_uses AS maxUses,
               p.starts_at AS startsAt, p.ends_at AS endsAt,
               p.is_active AS isActive,
               p.maGianHang,
               g.tenGianHang AS canteenName,
               (SELECT COUNT(*) FROM user_saved_vouchers uv WHERE uv.promotion_id = p.id) AS soLuotLuu
        FROM promotions p
        LEFT JOIN gianhang g ON g.maGianHang = p.maGianHang
        ORDER BY p.id DESC
      `);
      res.json({ success: true, data: rows });
    } catch (err) { next(err); }
  },

  /** POST /api/admin/vouchers — Tạo voucher toàn sàn (maGianHang = NULL) */
  createVoucher: async (req, res, next) => {
    try {
      const { code, title, description, discountPercent, maxUses, startsAt, endsAt, maGianHang } = req.body;
      if (!code || !title || !discountPercent)
        return res.status(400).json({ success: false, message: 'Thiếu thông tin voucher.' });

      await query(
        `INSERT INTO promotions (code, title, description, discount_percent, max_uses, starts_at, ends_at, maGianHang, is_active)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, TRUE)`,
        [code, title, description || '', discountPercent, maxUses ?? null, startsAt ?? null, endsAt ?? null, maGianHang ?? null]
      );
      res.status(201).json({ success: true, message: 'Tạo voucher thành công!' });
    } catch (err) {
      if (err.code === 'ER_DUP_ENTRY')
        return res.status(400).json({ success: false, message: 'Mã voucher đã tồn tại.' });
      next(err);
    }
  },

  /** PUT /api/admin/vouchers/:id */
  updateVoucher: async (req, res, next) => {
    try {
      const { id } = req.params;
      const { title, description, discountPercent, maxUses, startsAt, endsAt, isActive } = req.body;
      await query(
        `UPDATE promotions SET
           title            = COALESCE(?, title),
           description      = COALESCE(?, description),
           discount_percent = COALESCE(?, discount_percent),
           max_uses         = COALESCE(?, max_uses),
           starts_at        = COALESCE(?, starts_at),
           ends_at          = COALESCE(?, ends_at),
           is_active        = COALESCE(?, is_active)
         WHERE id = ?`,
        [title ?? null, description ?? null, discountPercent ?? null, maxUses ?? null,
         startsAt ?? null, endsAt ?? null, isActive ?? null, id]
      );
      res.json({ success: true, message: 'Cập nhật voucher thành công!' });
    } catch (err) { next(err); }
  },

  /** DELETE /api/admin/vouchers/:id */
  deleteVoucher: async (req, res, next) => {
    try {
      const { id } = req.params;
      await query(`DELETE FROM user_saved_vouchers WHERE promotion_id = ?`, [id]);
      await query(`DELETE FROM promotions WHERE id = ?`, [id]);
      res.json({ success: true, message: 'Xóa voucher thành công!' });
    } catch (err) { next(err); }
  },
};

module.exports = AdminController;

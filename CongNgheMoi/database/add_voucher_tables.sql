-- ============================================================
-- MIGRATION: Thêm bảng promotions và user_saved_vouchers
-- Chạy file này sau khi đã import 1.sql
-- Database: school_canteen
-- Khóa ngoại dùng gianhang.maGianHang và monan.maMonAn
-- ============================================================

USE `school_canteen`;

-- ── 1. Bảng promotions (voucher do staff tạo) ────────────────────────────────
CREATE TABLE IF NOT EXISTS `promotions` (
  `id`               INT(11)        NOT NULL AUTO_INCREMENT,
  `maGianHang`       INT(11)        NOT NULL COMMENT 'FK → gianhang.maGianHang',
  `maMonAn`          INT(11)        NULL     COMMENT 'NULL = áp dụng toàn gian hàng',
  `code`             VARCHAR(40)    NULL     COMMENT 'Mã voucher (VD: SALE20)',
  `title`            VARCHAR(255)   NOT NULL COMMENT 'Tên chương trình',
  `description`      TEXT           NULL,
  `discount_percent` DECIMAL(5,2)   NULL     COMMENT 'Phần trăm giảm (0-100)',
  `banner_image_url` VARCHAR(500)   NULL,
  `starts_at`        DATETIME       NULL     DEFAULT CURRENT_TIMESTAMP,
  `ends_at`          DATETIME       NOT NULL COMMENT 'Bắt buộc có ngày hết hạn',
  `is_active`        TINYINT(1)     NOT NULL DEFAULT 1,
  `created_at`       DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_gianhang` (`maGianHang`),
  KEY `idx_monan`    (`maMonAn`),
  KEY `idx_active`   (`is_active`, `ends_at`),
  CONSTRAINT `promotions_ibfk_gianhang` FOREIGN KEY (`maGianHang`) REFERENCES `gianhang` (`maGianHang`) ON DELETE CASCADE,
  CONSTRAINT `promotions_ibfk_monan`    FOREIGN KEY (`maMonAn`)    REFERENCES `monan`    (`maMonAn`)    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Chương trình khuyến mãi / voucher do staff tạo';

-- ── 2. Bảng user_saved_vouchers (voucher khách đã thu thập) ──────────────────
CREATE TABLE IF NOT EXISTS `user_saved_vouchers` (
  `id`           INT(11)   NOT NULL AUTO_INCREMENT,
  `maTaiKhoan`   INT(11)   NOT NULL COMMENT 'FK → taikhoan.maTaiKhoan',
  `promotion_id` INT(11)   NOT NULL COMMENT 'FK → promotions.id',
  `saved_at`     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_user_promo` (`maTaiKhoan`, `promotion_id`),
  KEY `idx_user`      (`maTaiKhoan`),
  KEY `idx_promotion` (`promotion_id`),
  CONSTRAINT `usv_ibfk_taikhoan`  FOREIGN KEY (`maTaiKhoan`)   REFERENCES `taikhoan`   (`maTaiKhoan`) ON DELETE CASCADE,
  CONSTRAINT `usv_ibfk_promotion` FOREIGN KEY (`promotion_id`) REFERENCES `promotions`  (`id`)        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Voucher mà khách hàng đã thu thập';

-- ── 3. Dữ liệu mẫu promotions ────────────────────────────────────────────────
-- maGianHang: 1=Cơm Gà, 2=Bún Bò, 3=Trà Sữa, 4=Cơm Tấm, 5=Bánh Mì, 6=Ăn Vặt
INSERT INTO `promotions`
  (`maGianHang`, `maMonAn`, `code`, `title`, `description`, `discount_percent`, `starts_at`, `ends_at`, `is_active`)
VALUES
  (1, NULL, 'COMGA20',  'Giảm 20% tất cả cơm gà',      'Áp dụng toàn bộ món tại Cơm Gà Xối Mỡ Cô Ba',    20.00, NOW(), DATE_ADD(NOW(), INTERVAL 7  DAY), 1),
  (2, NULL, 'BUNBO15',  'Giảm 15% bún bò & hủ tiếu',   'Áp dụng toàn bộ món tại Bún Bò & Hủ Tiếu Chú Năm',15.00, NOW(), DATE_ADD(NOW(), INTERVAL 3  DAY), 1),
  (3, NULL, 'TRASUA10', 'Giảm 10% đồ uống',             'Toàn bộ trà sữa tại T-Station',                   10.00, NOW(), DATE_ADD(NOW(), INTERVAL 14 DAY), 1),
  (4, NULL, 'COMTAM25', 'Giảm 25% cơm tấm cuối tuần',  'Thứ 7 & Chủ nhật tại Cơm Tấm Sinh Viên',          25.00, NOW(), DATE_ADD(NOW(), INTERVAL 5  DAY), 1),
  (5, 12,   'BANHMI30', 'Giảm 30% bánh mì heo quay',   'Chỉ áp dụng cho Bánh Mì Heo Quay',               30.00, NOW(), DATE_ADD(NOW(), INTERVAL 2  DAY), 1),
  (6, NULL, 'ANVAT10',  'Giảm 10% toàn bộ ăn vặt',     'Toàn bộ món tại Góc Ăn Vặt Tòa H',               10.00, NOW(), DATE_ADD(NOW(), INTERVAL 10 DAY), 1);

-- ============================================================
-- Xong! Kiểm tra:
--   SELECT * FROM promotions;
--   SELECT * FROM user_saved_vouchers;
-- ============================================================

-- Migration: Thêm cột max_uses vào promotions
-- Chạy file này trong phpMyAdmin hoặc MySQL CLI
USE `school_canteen`;

ALTER TABLE `promotions`
  ADD COLUMN `max_uses` INT NULL DEFAULT NULL
  COMMENT 'NULL = không giới hạn số lần sử dụng'
  AFTER `is_active`;

-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Apr 21, 2026 at 03:12 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `school_canteen`
--

-- --------------------------------------------------------

--
-- Table structure for table `chitietdonhang`
--

CREATE TABLE `chitietdonhang` (
  `maChiTietDonHang` int(11) NOT NULL,
  `maDonHang` int(11) DEFAULT NULL,
  `maMonAn` int(11) DEFAULT NULL,
  `soLuong` int(11) NOT NULL,
  `giaTien` decimal(12,0) NOT NULL COMMENT 'Lưu giá tại thời điểm đặt'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `chitietdonhang`
--

INSERT INTO `chitietdonhang` (`maChiTietDonHang`, `maDonHang`, `maMonAn`, `soLuong`, `giaTien`) VALUES
(1, 1, 3, 2, 25000),
(2, 2, 6, 1, 20000),
(3, 3, 1, 1, 38000),
(1001, 101, 1, 1, 38000),
(1002, 101, 16, 1, 10000),
(1003, 101, 8, 1, 20000),
(1004, 102, 4, 1, 40000),
(1005, 102, 7, 1, 25000),
(1006, 103, 10, 1, 25000),
(1007, 103, 8, 1, 20000),
(1008, 104, 5, 1, 35000),
(1009, 104, 12, 1, 18000),
(1010, 105, 7, 1, 25000),
(1011, 105, 9, 1, 25000),
(1012, 106, 1, 1, 38000),
(2001, 201, 4, 1, 40000),
(2002, 202, 3, 1, 25000),
(2003, 202, 7, 1, 25000),
(2004, 202, 9, 1, 25000),
(2005, 203, 6, 1, 20000),
(2006, 203, 13, 1, 20000),
(2007, 204, 14, 1, 20000),
(2008, 204, 15, 2, 15000),
(2009, 205, 11, 1, 35000),
(2010, 205, 8, 1, 20000),
(2011, 206, 3, 1, 25000),
(2012, 206, 16, 1, 10000);

-- --------------------------------------------------------

--
-- Table structure for table `danhgia`
--

CREATE TABLE `danhgia` (
  `maDanhGia` int(11) NOT NULL,
  `maDonHang` int(11) DEFAULT NULL,
  `maMonAn` int(11) DEFAULT NULL,
  `soSao` int(11) DEFAULT NULL CHECK (`soSao` >= 1 and `soSao` <= 5),
  `binhLuan` text DEFAULT NULL,
  `hinhAnhDanhGia` text DEFAULT NULL COMMENT 'JSON array chứa URL ảnh đánh giá',
  `thoiGianDanhGia` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `danhgia`
--

INSERT INTO `danhgia` (`maDanhGia`, `maDonHang`, `maMonAn`, `soSao`, `binhLuan`, `hinhAnhDanhGia`, `thoiGianDanhGia`) VALUES
(1, 3, 1, 3, 't', NULL, '2026-04-20 12:20:54');

-- --------------------------------------------------------

--
-- Table structure for table `danhmuc`
--

CREATE TABLE `danhmuc` (
  `maDanhMuc` int(11) NOT NULL,
  `tenDanhMuc` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `danhmuc`
--

INSERT INTO `danhmuc` (`maDanhMuc`, `tenDanhMuc`) VALUES
(1, 'Cơm'),
(2, 'Đồ uống'),
(3, 'Trà sữa'),
(4, 'Ăn vặt'),
(5, 'Tráng miệng'),
(6, 'Bún');

-- --------------------------------------------------------

--
-- Table structure for table `donhang`
--

CREATE TABLE `donhang` (
  `maDonHang` int(11) NOT NULL,
  `maTaiKhoan` int(11) DEFAULT NULL,
  `maNhomGiaoHang` int(11) DEFAULT NULL,
  `tongTien` decimal(12,0) DEFAULT NULL,
  `toaNha` varchar(50) DEFAULT NULL,
  `tang` varchar(50) DEFAULT NULL,
  `phong` varchar(50) DEFAULT NULL,
  `trangThaiDonHang` varchar(50) DEFAULT NULL COMMENT 'choXacNhan, dangChuanBi, choGiaoHang, dangGiao, daGiao, daHuy',
  `thoiGianDat` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `donhang`
--

INSERT INTO `donhang` (`maDonHang`, `maTaiKhoan`, `maNhomGiaoHang`, `tongTien`, `toaNha`, `tang`, `phong`, `trangThaiDonHang`, `thoiGianDat`) VALUES
(1, 4, NULL, 50000, 'A', 'Tầng 1', '1', 'daGiao', '2026-04-19 12:13:34'),
(2, 4, 1, 20000, 'A', 'Tầng 1', '1', 'daGiao', '2026-04-19 13:37:50'),
(3, 4, 1, 38000, 'A', 'Tầng 1', '1', 'daGiao', '2026-04-19 13:51:46'),
(101, 2, NULL, 73000, 'A', '2', '201', 'daGiao', '2026-03-10 11:30:00'),
(102, 2, NULL, 75000, 'A', '2', '201', 'daGiao', '2026-03-15 12:00:00'),
(103, 2, NULL, 40000, 'B', '3', '305', 'daGiao', '2026-03-20 09:30:00'),
(104, 2, NULL, 45000, 'B', '3', '305', 'daGiao', '2026-03-25 10:00:00'),
(105, 2, NULL, 50000, 'C', '1', '102', 'daGiao', '2026-04-01 12:30:00'),
(106, 2, NULL, 38000, 'C', '1', '102', 'daGiao', '2026-04-05 11:00:00'),
(201, 4, NULL, 40000, 'D', '4', '401', 'daGiao', '2026-03-12 10:30:00'),
(202, 4, NULL, 70000, 'D', '4', '401', 'daGiao', '2026-03-18 11:30:00'),
(203, 4, NULL, 50000, 'D', '2', '205', 'daGiao', '2026-03-22 09:00:00'),
(204, 4, NULL, 60000, 'D', '2', '205', 'daGiao', '2026-04-02 12:00:00'),
(205, 4, NULL, 55000, 'A', '1', '105', 'daGiao', '2026-04-08 11:00:00'),
(206, 4, NULL, 36000, 'A', '1', '105', 'daGiao', '2026-04-10 10:30:00');

-- --------------------------------------------------------

--
-- Table structure for table `gianhang`
--

CREATE TABLE `gianhang` (
  `maGianHang` int(11) NOT NULL,
  `maTaiKhoan` int(11) DEFAULT NULL,
  `tenGianHang` varchar(100) NOT NULL,
  `moTa` text DEFAULT NULL,
  `banner` varchar(255) DEFAULT NULL,
  `soDienThoai` varchar(20) DEFAULT NULL,
  `gioMoCua` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `gianhang`
--

INSERT INTO `gianhang` (`maGianHang`, `maTaiKhoan`, `tenGianHang`, `moTa`, `banner`, `soDienThoai`, `gioMoCua`) VALUES
(1, 101, 'Cơm Gà Xối Mỡ Cô Ba', 'Chuyên cơm gà xối mỡ đùi góc tư siêu to, da giòn rụm, kèm canh rong biển thanh mát. Có thêm cơm chiên dương châu.', 'https://img.freepik.com/free-photo/roasted-chicken-rice-served-with-chili-sauce-cucumber_1150-35678.jpg', '0911111111', '07:00 - 15:30'),
(2, 102, 'Bún Bò & Hủ Tiếu Chú Năm', 'Đậm đà hương vị truyền thống. Nước dùng hầm từ xương bò 10 tiếng. Quán có bán kèm hủ tiếu gõ và mì xào giòn.', 'https://img.freepik.com/free-photo/vietnamese-beef-noodle-soup-pho-with-herbs-lime_1150-35682.jpg', '0922222222', '06:00 - 13:00'),
(3, 103, 'Trà Sữa T-Station', 'Trạm tiếp nhiên liệu cho những giờ học căng thẳng! Menu đa dạng từ trà sữa trân châu đường đen, trà đào cam sả đến các loại đá xay.', 'https://img.freepik.com/free-photo/bubble-tea-with-tapioca-pearls_1150-42861.jpg', '0933333333', '07:30 - 17:00'),
(4, 104, 'Cơm Tấm Sinh Viên', 'Bao no, bao rẻ. Sườn nướng than hoa thơm lừng mắm tỏi. Có thêm chả cua, trứng ốp la đào và bì thính tự làm.', 'https://img.freepik.com/free-photo/vietnamese-broken-rice-with-grilled-pork-chop_1150-42862.jpg', '0944444444', '09:00 - 14:00'),
(5, 105, 'Bánh Mì Kẹp & Fast Food', 'Giải pháp ăn sáng thần tốc cho sinh viên chạy deadline. Bánh mì heo quay, xíu mại trứng muối và hamburger bò băm.', 'https://img.freepik.com/free-photo/vietnamese-sandwich-banh-mi-with-pork-vegetables_1150-35680.jpg', '0955555555', '06:30 - 16:00'),
(6, 106, 'Góc Ăn Vặt Tòa H', 'Thiên đường ăn vặt với cá viên chiên mắm, bánh tráng trộn, trái cây tô và xúc xích nướng đá. Freeship tận phòng nếu đặt trên 5 món.', 'https://img.freepik.com/free-photo/assortment-fried-snacks-with-sauce_1150-35685.jpg', '0966666666', '08:00 - 17:30');

-- --------------------------------------------------------

--
-- Table structure for table `giohang`
--

CREATE TABLE `giohang` (
  `maTaiKhoan` int(11) NOT NULL,
  `maMonAn` int(11) NOT NULL,
  `soLuong` int(11) NOT NULL DEFAULT 1 COMMENT 'Số lượng món ăn trong giỏ'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Lưu trữ giỏ hàng của người dùng';

-- --------------------------------------------------------

--
-- Table structure for table `monan`
--

CREATE TABLE `monan` (
  `maMonAn` int(11) NOT NULL,
  `maGianHang` int(11) DEFAULT NULL,
  `maDanhMuc` int(11) DEFAULT NULL,
  `tenMonAn` varchar(100) NOT NULL,
  `moTa` text DEFAULT NULL COMMENT 'Mô tả chi tiết món ăn',
  `giaTien` decimal(12,0) NOT NULL COMMENT 'Giá VND',
  `hinhAnh` varchar(255) DEFAULT NULL,
  `trangThai` tinyint(1) DEFAULT 1 COMMENT '1: Còn hàng, 0: Hết hàng',
  `daXoa` tinyint(1) DEFAULT 0 COMMENT '0: Bình thường, 1: Đã xóa mềm',
  `diemDanhGia` decimal(2,1) DEFAULT 0.0 COMMENT 'Điểm đánh giá trung bình (1.0 - 5.0)',
  `luotDanhGia` int(11) DEFAULT 0 COMMENT 'Tổng lượt đánh giá',
  `soLuongDaBan` int(11) DEFAULT 0 COMMENT 'Tổng số lượng đã bán'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `monan`
--

INSERT INTO `monan` (`maMonAn`, `maGianHang`, `maDanhMuc`, `tenMonAn`, `moTa`, `giaTien`, `hinhAnh`, `trangThai`, `daXoa`, `diemDanhGia`, `luotDanhGia`, `soLuongDaBan`) VALUES
(1, 1, 1, 'Cơm gà xối mỡ đùi góc tư', 'Đùi gà góc tư da giòn rụm, thịt mềm đậm vị. Xối mỡ hành phi thơm lừng, ăn kèm cơm trắng dẻo và nước kho gà.', 38000, 'https://example.com/com-ga-dui.jpg', 0, 0, 3.0, 1, 0),
(2, 1, 1, 'Cơm gà xối mỡ cánh', 'Cánh gà xối mỡ vàng ươm, da giòn tan. Ăn kèm dưa leo và nước mắm chua ngọt pha đúng vị.', 30000, 'https://example.com/com-ga-canh.jpg', 1, 1, 0.0, 0, 0),
(3, 1, 1, 'Cơm chiên Dương Châu', 'Cơm chiên thập cẩm với tôm, trứng, xúc xích và rau củ tươi. Xào lửa lớn phi thơm mỡ hành vàng óng.', 25000, 'https://example.com/com-chien.jpg', 1, 0, 0.0, 0, 0),
(4, 2, 6, 'Bún bò Huế tô đặc biệt', 'Nước dùng hầm xương bò 10 tiếng, đậm đà hương sả và mắm ruốc đặc trưng. Tô đặc biệt có đủ bò, chả Huế, móng heo.', 40000, 'https://example.com/bun-bo-dac-biet.jpg', 1, 0, 0.0, 0, 0),
(5, 2, 6, 'Bún bò giò heo', 'Bún bò Huế chuẩn vị với giò heo mềm, thịt bò thái lát. Nước dùng cay nhẹ, thơm sả ớt.', 35000, 'https://example.com/bun-bo-gio.jpg', 1, 0, 0.0, 0, 0),
(6, 2, 6, 'Hủ tiếu gõ thịt băm', 'Hủ tiếu dai mềm chan nước dùng ngọt từ xương ống, ăn kèm thịt băm và hành phi giòn.', 20000, 'https://example.com/hu-tieu.jpg', 1, 0, 0.0, 0, 0),
(7, 3, 3, 'Trà sữa trân châu đường đen', 'Trà sữa thơm mịn pha cùng đường đen đặc. Trân châu dai mềm ngâm nước đường đen sánh quyện.', 25000, 'https://example.com/tra-sua-tcdd.jpg', 1, 0, 0.0, 0, 0),
(8, 3, 2, 'Trà đào cam sả', 'Vị chua ngọt nhẹ của đào pha cùng tinh dầu sả và nước cam tươi. Thanh mát, thích hợp cho ngày nóng.', 20000, 'https://example.com/tra-dao.jpg', 1, 0, 0.0, 0, 0),
(9, 3, 3, 'Sữa tươi trân châu đường đen', 'Sữa tươi béo ngậy kết hợp trân châu đường đen dẻo mềm. Vị ngọt thanh, uống mát lạnh giải nhiệt.', 25000, 'https://example.com/sua-tuoi.jpg', 1, 0, 0.0, 0, 0),
(10, 4, 1, 'Cơm tấm sườn nướng', 'Sườn non nướng than hoa thơm lừng mắm tỏi, cơm tấm dẻo mịn. Ăn kèm chả trứng và bì thính tự làm.', 25000, 'https://example.com/com-suon.jpg', 1, 0, 0.0, 0, 0),
(11, 4, 1, 'Cơm tấm sườn bì chả', 'Combo đầy đủ cơm tấm, sườn nướng, bì thính và chả cua. Nước mắm chua ngọt pha đúng vị miền Nam.', 35000, 'https://example.com/com-suon-bi-cha.jpg', 1, 0, 0.0, 0, 0),
(12, 5, 4, 'Bánh mì heo quay', 'Bánh mì giòn nhân heo quay da phồng, thơm phức. Kèm chả lụa, dưa chua và nước sốt đặc biệt.', 18000, 'https://example.com/bm-heo-quay.jpg', 1, 0, 0.0, 0, 0),
(13, 5, 4, 'Bánh mì xíu mại trứng muối', 'Bánh mì nhân xíu mại thịt heo đậm đà ăn kèm trứng muối bùi béo. Sốt tương đỏ thơm ngon.', 20000, 'https://example.com/bm-xiu-mai.jpg', 1, 0, 0.0, 0, 0),
(14, 6, 4, 'Cá viên chiên mắm (Phần nhỏ)', 'Cá viên chiên giòn rụm chấm nước mắm pha tỏi ớt cay ngọt. Ăn vặt lý tưởng giữa giờ học.', 20000, 'https://example.com/ca-vien.jpg', 1, 0, 0.0, 0, 0),
(15, 6, 4, 'Bánh tráng trộn khô bò', 'Bánh tráng trộn đủ topping: khô bò, trứng cút, hành phi, sa tế. Vị cay mặn ngọt hòa quyện.', 15000, 'https://example.com/banh-trang.jpg', 1, 0, 0.0, 0, 0),
(16, 1, NULL, 'Canh rong biển thêm', 'Canh rong biển nấu xương gà thanh mát, bổ sung khoáng chất. Ăn kèm bữa cơm hàng ngày.', 10000, 'https://example.com/canh-rong-bien.jpg', 1, 0, 0.0, 0, 0);

-- --------------------------------------------------------

--
-- Table structure for table `nhomgiaohang`
--

CREATE TABLE `nhomgiaohang` (
  `maNhomGiaoHang` int(11) NOT NULL,
  `maNhanVienGiaoHang` int(11) DEFAULT NULL COMMENT 'Nhân viên tiếp nhận',
  `toaNha` varchar(50) NOT NULL,
  `tang` varchar(50) NOT NULL,
  `thoiGianTaoNhom` datetime DEFAULT NULL,
  `trangThaiNhom` varchar(50) DEFAULT NULL COMMENT 'choGiaoHang, dangGiao, hoanThanh'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `nhomgiaohang`
--

INSERT INTO `nhomgiaohang` (`maNhomGiaoHang`, `maNhanVienGiaoHang`, `toaNha`, `tang`, `thoiGianTaoNhom`, `trangThaiNhom`) VALUES
(1, NULL, 'A', 'Tầng 1', '2026-04-19 13:53:00', 'choGiaoHang');

-- --------------------------------------------------------

--
-- Table structure for table `taikhoan`
--

CREATE TABLE `taikhoan` (
  `maTaiKhoan` int(11) NOT NULL,
  `maVaiTro` int(11) DEFAULT NULL,
  `tenDangNhap` varchar(50) NOT NULL,
  `matKhau` varchar(255) NOT NULL COMMENT 'Chuỗi Hash',
  `hoTen` varchar(100) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `soDienThoai` varchar(20) DEFAULT NULL,
  `anhDaiDien` varchar(255) DEFAULT NULL,
  `trangThai` tinyint(1) DEFAULT 1 COMMENT '1: Hoạt động, 0: Khóa'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `taikhoan`
--

INSERT INTO `taikhoan` (`maTaiKhoan`, `maVaiTro`, `tenDangNhap`, `matKhau`, `hoTen`, `email`, `soDienThoai`, `anhDaiDien`, `trangThai`) VALUES
(2, 1, 'baostudent', '$2b$10$WFcjK6tD.pD36grkjqQsZO5emUBC8.Wu3ZpwaEaQa9YRN7Ppa4jeu', 'Nguyễn Văn Bảo', NULL, '0912345678', NULL, 1),
(4, 1, '123', '$2b$10$/HhEj0cf0ZfygX/3qnpPeOZR3XtwriJNT0Z1X0hzBh6oTEaEWuv7S', 'Duong Minh Quoc Bao', 'duongbao2304@gmail.com', '0353205835', '/img/anhdaidien/avatar-1776331958169-253758901.jpg', 1),
(101, 2, 'coba_comga', '$2b$10$/HhEj0cf0ZfygX/3qnpPeOZR3XtwriJNT0Z1X0hzBh6oTEaEWuv7S', 'Cô Ba Cơm Gà', NULL, '0911111111', NULL, 1),
(102, 2, 'chunam_bunbo', '$2b$10$/HhEj0cf0ZfygX/3qnpPeOZR3XtwriJNT0Z1X0hzBh6oTEaEWuv7S', 'Chú Năm Bún Bò', NULL, '0922222222', NULL, 1),
(103, 2, 'trasua_station', '$2b$10$DBZrrKqHc9IPJ8LT2UboleeaNmUGl81kWBhq.sBuRoz...', 'Nguyễn Thị Nước', NULL, '0933333333', NULL, 1),
(104, 2, 'comtam_sv', '$2b$10$DBZrrKqHc9IPJ8LT2UboleeaNmUGl81kWBhq.sBuRoz...', 'Trần Cơm Tấm', NULL, '0944444444', NULL, 1),
(105, 2, 'banhmi_hot', '$2b$10$DBZrrKqHc9IPJ8LT2UboleeaNmUGl81kWBhq.sBuRoz...', 'Lê Bánh Mì', NULL, '0955555555', NULL, 1),
(106, 2, 'anvat_toah', '$2b$10$DBZrrKqHc9IPJ8LT2UboleeaNmUGl81kWBhq.sBuRoz...', 'Phạm Ăn Vặt', NULL, '0966666666', NULL, 1);

-- --------------------------------------------------------

--
-- Table structure for table `thanhtoan`
--

CREATE TABLE `thanhtoan` (
  `maThanhToan` int(11) NOT NULL,
  `maDonHang` int(11) DEFAULT NULL,
  `phuongThuc` varchar(50) DEFAULT NULL COMMENT 'tienMat, chuyenKhoan',
  `trangThai` varchar(50) DEFAULT NULL COMMENT 'chuaThanhToan, daThanhToan, hoanTien'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `vaitro`
--

CREATE TABLE `vaitro` (
  `maVaiTro` int(11) NOT NULL,
  `tenVaiTro` varchar(50) NOT NULL COMMENT 'khachHang, nhanVienCanTin, nhanVienGiaoHang'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `vaitro`
--

INSERT INTO `vaitro` (`maVaiTro`, `tenVaiTro`) VALUES
(1, 'khachHang'),
(2, 'nhanVienCanTin'),
(3, 'nhanVienGiaoHang');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `chitietdonhang`
--
ALTER TABLE `chitietdonhang`
  ADD PRIMARY KEY (`maChiTietDonHang`),
  ADD KEY `maDonHang` (`maDonHang`),
  ADD KEY `maMonAn` (`maMonAn`);

--
-- Indexes for table `danhgia`
--
ALTER TABLE `danhgia`
  ADD PRIMARY KEY (`maDanhGia`),
  ADD KEY `maDonHang` (`maDonHang`),
  ADD KEY `maMonAn` (`maMonAn`);

--
-- Indexes for table `danhmuc`
--
ALTER TABLE `danhmuc`
  ADD PRIMARY KEY (`maDanhMuc`);

--
-- Indexes for table `donhang`
--
ALTER TABLE `donhang`
  ADD PRIMARY KEY (`maDonHang`),
  ADD KEY `maTaiKhoan` (`maTaiKhoan`),
  ADD KEY `maNhomGiaoHang` (`maNhomGiaoHang`);

--
-- Indexes for table `gianhang`
--
ALTER TABLE `gianhang`
  ADD PRIMARY KEY (`maGianHang`),
  ADD KEY `maTaiKhoan` (`maTaiKhoan`);

--
-- Indexes for table `giohang`
--
ALTER TABLE `giohang`
  ADD PRIMARY KEY (`maTaiKhoan`,`maMonAn`),
  ADD KEY `maMonAn` (`maMonAn`);

--
-- Indexes for table `monan`
--
ALTER TABLE `monan`
  ADD PRIMARY KEY (`maMonAn`),
  ADD KEY `maGianHang` (`maGianHang`),
  ADD KEY `maDanhMuc` (`maDanhMuc`);

--
-- Indexes for table `nhomgiaohang`
--
ALTER TABLE `nhomgiaohang`
  ADD PRIMARY KEY (`maNhomGiaoHang`),
  ADD KEY `maNhanVienGiaoHang` (`maNhanVienGiaoHang`);

--
-- Indexes for table `taikhoan`
--
ALTER TABLE `taikhoan`
  ADD PRIMARY KEY (`maTaiKhoan`),
  ADD UNIQUE KEY `tenDangNhap` (`tenDangNhap`),
  ADD KEY `maVaiTro` (`maVaiTro`);

--
-- Indexes for table `thanhtoan`
--
ALTER TABLE `thanhtoan`
  ADD PRIMARY KEY (`maThanhToan`),
  ADD KEY `maDonHang` (`maDonHang`);

--
-- Indexes for table `vaitro`
--
ALTER TABLE `vaitro`
  ADD PRIMARY KEY (`maVaiTro`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `chitietdonhang`
--
ALTER TABLE `chitietdonhang`
  MODIFY `maChiTietDonHang` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2013;

--
-- AUTO_INCREMENT for table `danhgia`
--
ALTER TABLE `danhgia`
  MODIFY `maDanhGia` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `danhmuc`
--
ALTER TABLE `danhmuc`
  MODIFY `maDanhMuc` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `donhang`
--
ALTER TABLE `donhang`
  MODIFY `maDonHang` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=207;

--
-- AUTO_INCREMENT for table `gianhang`
--
ALTER TABLE `gianhang`
  MODIFY `maGianHang` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `monan`
--
ALTER TABLE `monan`
  MODIFY `maMonAn` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT for table `nhomgiaohang`
--
ALTER TABLE `nhomgiaohang`
  MODIFY `maNhomGiaoHang` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `taikhoan`
--
ALTER TABLE `taikhoan`
  MODIFY `maTaiKhoan` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=107;

--
-- AUTO_INCREMENT for table `thanhtoan`
--
ALTER TABLE `thanhtoan`
  MODIFY `maThanhToan` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `vaitro`
--
ALTER TABLE `vaitro`
  MODIFY `maVaiTro` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `chitietdonhang`
--
ALTER TABLE `chitietdonhang`
  ADD CONSTRAINT `chitietdonhang_ibfk_1` FOREIGN KEY (`maDonHang`) REFERENCES `donhang` (`maDonHang`),
  ADD CONSTRAINT `chitietdonhang_ibfk_2` FOREIGN KEY (`maMonAn`) REFERENCES `monan` (`maMonAn`);

--
-- Constraints for table `danhgia`
--
ALTER TABLE `danhgia`
  ADD CONSTRAINT `danhgia_ibfk_1` FOREIGN KEY (`maDonHang`) REFERENCES `donhang` (`maDonHang`),
  ADD CONSTRAINT `danhgia_ibfk_2` FOREIGN KEY (`maMonAn`) REFERENCES `monan` (`maMonAn`);

--
-- Constraints for table `donhang`
--
ALTER TABLE `donhang`
  ADD CONSTRAINT `donhang_ibfk_1` FOREIGN KEY (`maTaiKhoan`) REFERENCES `taikhoan` (`maTaiKhoan`),
  ADD CONSTRAINT `donhang_ibfk_2` FOREIGN KEY (`maNhomGiaoHang`) REFERENCES `nhomgiaohang` (`maNhomGiaoHang`);

--
-- Constraints for table `gianhang`
--
ALTER TABLE `gianhang`
  ADD CONSTRAINT `gianhang_ibfk_1` FOREIGN KEY (`maTaiKhoan`) REFERENCES `taikhoan` (`maTaiKhoan`);

--
-- Constraints for table `giohang`
--
ALTER TABLE `giohang`
  ADD CONSTRAINT `giohang_ibfk_1` FOREIGN KEY (`maTaiKhoan`) REFERENCES `taikhoan` (`maTaiKhoan`) ON DELETE CASCADE,
  ADD CONSTRAINT `giohang_ibfk_2` FOREIGN KEY (`maMonAn`) REFERENCES `monan` (`maMonAn`) ON DELETE CASCADE;

--
-- Constraints for table `monan`
--
ALTER TABLE `monan`
  ADD CONSTRAINT `monan_ibfk_1` FOREIGN KEY (`maGianHang`) REFERENCES `gianhang` (`maGianHang`),
  ADD CONSTRAINT `monan_ibfk_2` FOREIGN KEY (`maDanhMuc`) REFERENCES `danhmuc` (`maDanhMuc`) ON DELETE SET NULL;

--
-- Constraints for table `nhomgiaohang`
--
ALTER TABLE `nhomgiaohang`
  ADD CONSTRAINT `nhomgiaohang_ibfk_1` FOREIGN KEY (`maNhanVienGiaoHang`) REFERENCES `taikhoan` (`maTaiKhoan`);

--
-- Constraints for table `taikhoan`
--
ALTER TABLE `taikhoan`
  ADD CONSTRAINT `taikhoan_ibfk_1` FOREIGN KEY (`maVaiTro`) REFERENCES `vaitro` (`maVaiTro`);

--
-- Constraints for table `thanhtoan`
--
ALTER TABLE `thanhtoan`
  ADD CONSTRAINT `thanhtoan_ibfk_1` FOREIGN KEY (`maDonHang`) REFERENCES `donhang` (`maDonHang`);

-- ============================================================
-- Dữ liệu mẫu: Đánh giá (danhgia)
-- Xóa dữ liệu test cũ và thêm dữ liệu mẫu chân thực
-- ============================================================
TRUNCATE TABLE `danhgia`;

INSERT INTO `danhgia` (`maDanhGia`, `maDonHang`, `maMonAn`, `soSao`, `binhLuan`, `hinhAnhDanhGia`, `thoiGianDanhGia`) VALUES
-- ═══ Đơn 101 (tài khoản 2 - baostudent) ═══
(1,  101, 1,  5, 'Cơm gà da giòn, thịt đậm vị, ăn rất ngon! Sẽ order lại.', NULL, '2026-03-11 08:00:00'),
(2,  101, 16, 4, 'Canh rong biển thanh, nhẹ vị. Hơi ít nhưng ngon.', NULL, '2026-03-11 08:01:00'),
(3,  101, 8,  5, 'Trà đào cam sả rất thơm, vị chua nhẹ cân bằng. Siêu ngon!', NULL, '2026-03-11 08:02:00'),
-- ═══ Đơn 102 ═══
(4,  102, 4,  5, 'Bún bò Huế đậm đà hương vị chuẩn, nước dùng thơm nức, thịt mềm.', NULL, '2026-03-16 09:00:00'),
(5,  102, 7,  4, 'Trà sữa đường đen ngày nào cũng uống được! Hơi ngọt một chút.', NULL, '2026-03-16 09:01:00'),
-- ═══ Đơn 103 ═══
(6,  103, 10, 4, 'Cơm tấm sườn nướng mắm tỏi thơm, cơm dẻo vừa ăn. OK lắm.', NULL, '2026-03-21 11:00:00'),
(7,  103, 8,  5, 'Trà đào quán này là số 1, mát lạnh đúng điệu buổi trưa.', NULL, '2026-03-21 11:01:00'),
-- ═══ Đơn 104 ═══
(8,  104, 5,  3, 'Bún bò giò heo tạm ổn, nước dùng hơi nhạt so với kỳ vọng.', NULL, '2026-03-26 10:00:00'),
(9,  104, 12, 4, 'Bánh mì heo quay vỏ giòn, nhân đầy đặn. Giá hợp lý.', NULL, '2026-03-26 10:01:00'),
-- ═══ Đơn 105 ═══
(10, 105, 7,  5, 'Trà sữa trân châu đường đen sánh quyện, trân châu dẻo ngon!', NULL, '2026-04-02 12:30:00'),
(11, 105, 9,  4, 'Sữa tươi trân châu uống rất mát, không quá ngọt.', NULL, '2026-04-02 12:31:00'),
-- ═══ Đơn 106 ═══
(12, 106, 1,  4, 'Cơm gà vẫn ngon như lần trước, da giòn, thịt không bị khô.', NULL, '2026-04-06 11:00:00'),
-- ═══ Đơn 201 (tài khoản 4 - duong) ═══
(13, 201, 4,  5, 'Tô bún bò siêu to, thịt nhiều, ăn no căng. Quá ngon!', NULL, '2026-03-13 10:30:00'),
-- ═══ Đơn 202 ═══
(14, 202, 3,  4, 'Cơm chiên Dương Châu vừa ăn, nhiều rau, ít dầu mỡ.', NULL, '2026-03-19 11:30:00'),
(15, 202, 7,  5, 'Trà sữa đường đen đặc quánh, trân châu dai ngon. Like!', NULL, '2026-03-19 11:31:00'),
(16, 202, 9,  4, 'Sữa tươi trân châu mát lạnh, uống xong tỉnh ngủ liền.', NULL, '2026-03-19 11:32:00'),
-- ═══ Đơn 203 ═══
(17, 203, 6,  3, 'Hủ tiếu ổn nhưng nước dùng hơi nhạt, cần thêm gia vị.', NULL, '2026-03-23 09:00:00'),
(18, 203, 13, 4, 'Bánh mì xíu mại trứng muối thơm lừng, giá rẻ mà ngon.', NULL, '2026-03-23 09:01:00'),
-- ═══ Đơn 204 ═══
(19, 204, 14, 5, 'Cá viên chiên mắm cay giòn tan, ăn vặt buổi chiều quá đỉnh!', NULL, '2026-04-03 12:00:00'),
(20, 204, 15, 4, 'Bánh tráng trộn khô bò đủ vị chua cay mặn ngọt. Ngon!', NULL, '2026-04-03 12:01:00'),
-- ═══ Đơn 205 ═══
(21, 205, 11, 5, 'Cơm tấm sườn bì chả đầy đủ topping, sườn nướng thơm khói.', NULL, '2026-04-09 11:00:00'),
(22, 205, 8,  5, 'Trà đào cam sả nhà này làm chuẩn nhất trường, uống hoài.', NULL, '2026-04-09 11:01:00'),
-- ═══ Đơn 206 ═══
(23, 206, 3,  4, 'Cơm chiên Dương Châu chuẩn vị, hạt cơm tơi không vón cục.', NULL, '2026-04-11 10:30:00'),
(24, 206, 16, 3, 'Canh rong biển hơi lạt, cần thêm muối. Nhưng mà tươi.', NULL, '2026-04-11 10:31:00'),
-- ═══ Đơn 3 (test gốc – giữ lại để link với maDonHang=3) ═══
(25, 3, 1, 4, 'Cơm gà ngon, giao nhanh. Lần sau sẽ đặt thêm!', NULL, '2026-04-20 12:30:00');

-- Cập nhật AUTO_INCREMENT danhgia
ALTER TABLE `danhgia`
  MODIFY `maDanhGia` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

COMMIT;

-- ============================================================
-- Cập nhật điểm đánh giá trung bình và lượt đánh giá cho monan
-- ============================================================
UPDATE `monan` m
JOIN (
  SELECT
    maMonAn,
    ROUND(AVG(soSao), 1) AS avg_rating,
    COUNT(*)             AS total_count
  FROM `danhgia`
  GROUP BY maMonAn
) agg ON agg.maMonAn = m.maMonAn
SET
  m.diemDanhGia = agg.avg_rating,
  m.luotDanhGia = agg.total_count;

-- ============================================================
-- Cập nhật soLuongDaBan từ chi tiết đơn hàng đã giao
-- ============================================================
UPDATE `monan` m
JOIN (
  SELECT ct.maMonAn, SUM(ct.soLuong) AS tong
  FROM `chitietdonhang` ct
  JOIN `donhang` dh ON dh.maDonHang = ct.maDonHang
  WHERE dh.trangThaiDonHang = 'daGiao'
  GROUP BY ct.maMonAn
) sold ON sold.maMonAn = m.maMonAn
SET m.soLuongDaBan = sold.tong;

-- ============================================================
-- Cập nhật hình ảnh thực tế cho gian hàng
-- ============================================================
UPDATE `gianhang` SET `banner` = '/uploads/gianhang/comga.jpg' WHERE `maGianHang` = 1;
UPDATE `gianhang` SET `banner` = '/uploads/gianhang/chu5.jpg' WHERE `maGianHang` = 2;
UPDATE `gianhang` SET `banner` = '/uploads/gianhang/ts.jpg' WHERE `maGianHang` = 3;
UPDATE `gianhang` SET `banner` = '/uploads/gianhang/ctsv.jpg' WHERE `maGianHang` = 4;
UPDATE `gianhang` SET `banner` = '/uploads/gianhang/bm.jpg' WHERE `maGianHang` = 5;
UPDATE `gianhang` SET `banner` = '/uploads/gianhang/anvat.jpg' WHERE `maGianHang` = 6;

-- ============================================================
-- Cập nhật hình ảnh thực tế cho món ăn
-- ============================================================
UPDATE `monan` SET `hinhAnh` = '/uploads/monan/duigagoc4.jpg' WHERE `maMonAn` = 1;
UPDATE `monan` SET `hinhAnh` = '/uploads/monan/comgacanh.jpg' WHERE `maMonAn` = 2;
UPDATE `monan` SET `hinhAnh` = '/uploads/monan/comchien.jpg' WHERE `maMonAn` = 3;
UPDATE `monan` SET `hinhAnh` = '/uploads/monan/bbhdb.jpg' WHERE `maMonAn` = 4;
UPDATE `monan` SET `hinhAnh` = '/uploads/monan/bbhgh.webp' WHERE `maMonAn` = 5;
UPDATE `monan` SET `hinhAnh` = '/uploads/monan/htgtb.webp' WHERE `maMonAn` = 6;
UPDATE `monan` SET `hinhAnh` = '/uploads/monan/tsccd.webp' WHERE `maMonAn` = 7;
UPDATE `monan` SET `hinhAnh` = '/uploads/monan/tdcs.jpg' WHERE `maMonAn` = 8;
UPDATE `monan` SET `hinhAnh` = '/uploads/monan/st.jpg' WHERE `maMonAn` = 9;
UPDATE `monan` SET `hinhAnh` = '/uploads/monan/ctsn.jpg' WHERE `maMonAn` = 10;
UPDATE `monan` SET `hinhAnh` = '/uploads/monan/ctsbc.jpg' WHERE `maMonAn` = 11;
UPDATE `monan` SET `hinhAnh` = '/uploads/monan/bmhq.webp' WHERE `maMonAn` = 12;
UPDATE `monan` SET `hinhAnh` = '/uploads/monan/xmtm.jpg' WHERE `maMonAn` = 13;
UPDATE `monan` SET `hinhAnh` = '/uploads/monan/cvcm.jpg' WHERE `maMonAn` = 14;
UPDATE `monan` SET `hinhAnh` = '/uploads/monan/bttkb.jpg' WHERE `maMonAn` = 15;
UPDATE `monan` SET `hinhAnh` = '/uploads/monan/crb.jpg' WHERE `maMonAn` = 16;

-- ============================================================
-- Thêm cột số lượng tồn kho cho bảng monan
-- ============================================================
ALTER TABLE `monan` ADD COLUMN IF NOT EXISTS `soLuongTon` int(11) NOT NULL DEFAULT 99 COMMENT 'Số lượng tồn kho';
UPDATE `monan` SET `soLuongTon` = 99 WHERE `soLuongTon` = 0;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

-- ============================================================
-- MIGRATION: Update Address to Foreign Keys
-- ============================================================

-- 1. Create `toanha` table
CREATE TABLE IF NOT EXISTS `toanha` (
  `maToaNha` int(11) NOT NULL AUTO_INCREMENT,
  `tenToaNha` varchar(50) NOT NULL,
  PRIMARY KEY (`maToaNha`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Create `phong` table
CREATE TABLE IF NOT EXISTS `phong` (
  `maPhong` int(11) NOT NULL AUTO_INCREMENT,
  `maToaNha` int(11) NOT NULL,
  `tenPhong` varchar(50) NOT NULL,
  PRIMARY KEY (`maPhong`),
  CONSTRAINT `phong_ibfk_1` FOREIGN KEY (`maToaNha`) REFERENCES `toanha` (`maToaNha`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert some dummy data for the new tables so the UI works
INSERT INTO `toanha` (`maToaNha`, `tenToaNha`) VALUES 
(1, 'Tòa A'), (2, 'Tòa B'), (3, 'Tòa C'), (4, 'Tòa D'), (5, 'Tòa E'), (6, 'Tòa F'), (7, 'Tòa G'), (8, 'Tòa H'), (9, 'Tòa I');

INSERT INTO `phong` (`maPhong`, `maToaNha`, `tenPhong`) VALUES
(1, 1, '101'), (2, 1, '102'), (3, 1, '103'), (4, 1, '201'), (5, 1, '202'),
(6, 2, '101'), (7, 2, '201'), (8, 2, '305'),
(9, 3, '101'), (10, 3, '102'),
(11, 4, '205'), (12, 4, '401');

-- 3. Truncate tables to prevent foreign key issues and data type mismatch
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE `chitietdonhang`;
TRUNCATE TABLE `danhgia`;
TRUNCATE TABLE `thanhtoan`;
TRUNCATE TABLE `donhang`;
TRUNCATE TABLE `nhomgiaohang`;
SET FOREIGN_KEY_CHECKS = 1;

-- 4. Alter `donhang`
ALTER TABLE `donhang`
  DROP COLUMN `toaNha`,
  DROP COLUMN `tang`,
  DROP COLUMN `phong`,
  ADD COLUMN `maToaNha` int(11) DEFAULT NULL,
  ADD COLUMN `maPhong` int(11) DEFAULT NULL;

ALTER TABLE `donhang`
  ADD CONSTRAINT `donhang_ibfk_3` FOREIGN KEY (`maToaNha`) REFERENCES `toanha` (`maToaNha`),
  ADD CONSTRAINT `donhang_ibfk_4` FOREIGN KEY (`maPhong`) REFERENCES `phong` (`maPhong`);

-- 5. Alter `nhomgiaohang`
ALTER TABLE `nhomgiaohang`
  DROP COLUMN `toaNha`,
  DROP COLUMN `tang`,
  ADD COLUMN `maToaNha` int(11) DEFAULT NULL;

ALTER TABLE `nhomgiaohang`
  ADD CONSTRAINT `nhomgiaohang_ibfk_2` FOREIGN KEY (`maToaNha`) REFERENCES `toanha` (`maToaNha`);

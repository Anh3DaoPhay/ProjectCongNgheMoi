// lib/view/customer/voucher/voucher_service.dart
// Quản lý danh sách voucher + voucher đã thu thập.
// Mock data sẵn — khi backend sẵn sàng, thay bằng API calls.

import 'voucher_model.dart';

class VoucherService {
  VoucherService._();
  static final VoucherService instance = VoucherService._();

  // Voucher đã thu thập (sẽ kết nối backend sau)
  final List<Voucher> _myVouchers = [];
  List<Voucher> get myVouchers =>
      _myVouchers.where((v) => v.isValid).toList();

  // Voucher do staff tạo ra
  final List<Voucher> _staffVouchers = [];
  List<Voucher> get staffVouchers => List.unmodifiable(_staffVouchers);

  // Voucher available = mock data + staff vouchers (chỉ còn hạn)
  List<Voucher> get availableVouchers => [
        ..._staffVouchers.where((v) => v.isValid),
        ..._mockVouchers.where((v) => v.isValid),
      ];

  bool hasCollected(String voucherId) =>
      _myVouchers.any((v) => v.id == voucherId);

  void collectVoucher(Voucher v) {
    if (!hasCollected(v.id)) _myVouchers.add(v);
  }

  void removeVoucher(String id) => _myVouchers.removeWhere((v) => v.id == id);

  // ── Staff CRUD ─────────────────────────────────────────────────────────────
  void addStaffVoucher(Voucher v) => _staffVouchers.insert(0, v);

  void updateStaffVoucher(Voucher updated) {
    final idx = _staffVouchers.indexWhere((v) => v.id == updated.id);
    if (idx != -1) _staffVouchers[idx] = updated;
  }

  void deleteStaffVoucher(String id) =>
      _staffVouchers.removeWhere((v) => v.id == id);

  // ── Mock data (căn tin tạo ra) ────────────────────────────────────────────
  final List<Voucher> _mockVouchers = [
    Voucher(
      id: 'v001',
      code: 'COM20',
      title: 'Giảm 20% món cơm',
      description: 'Áp dụng cho tất cả món cơm tại căn tin A',
      restaurantName: 'Căn tin A',
      restaurantId: 'r001',
      categoryName: 'Cơm',
      discountPercent: 20,
      maxDiscount: 15000,
      totalQuantity: 50,
      usedQuantity: 12,
      expiredAt: DateTime.now().add(const Duration(days: 7)),
    ),
    Voucher(
      id: 'v002',
      code: 'DRINK15',
      title: 'Giảm 15% đồ uống',
      description: 'Áp dụng cho nước uống, sinh tố',
      restaurantName: 'Căn tin B',
      restaurantId: 'r002',
      categoryName: 'Đồ uống',
      discountPercent: 15,
      totalQuantity: 100,
      usedQuantity: 80,
      expiredAt: DateTime.now().add(const Duration(days: 3)),
    ),
    Voucher(
      id: 'v003',
      code: 'ALLFOOD10',
      title: 'Giảm 10% tất cả món',
      description: 'Không giới hạn loại món ăn',
      restaurantName: 'Căn tin C',
      restaurantId: 'r003',
      discountPercent: 10,
      maxDiscount: 20000,
      totalQuantity: 200,
      usedQuantity: 45,
      expiredAt: DateTime.now().add(const Duration(days: 14)),
    ),
    Voucher(
      id: 'v004',
      code: 'BANHMI30',
      title: 'Giảm 30% bánh mì',
      description: 'Áp dụng cho bánh mì các loại',
      restaurantName: 'Căn tin D',
      restaurantId: 'r004',
      categoryName: 'Ăn vặt',
      discountPercent: 30,
      totalQuantity: 30,
      usedQuantity: 30, // hết slot → tự ẩn
      expiredAt: DateTime.now().add(const Duration(days: 5)),
    ),
  ];
}

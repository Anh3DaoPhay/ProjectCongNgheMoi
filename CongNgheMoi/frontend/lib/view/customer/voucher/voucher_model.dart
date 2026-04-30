// lib/view/customer/voucher/voucher_model.dart

class Voucher {
  final String id;
  final String code;
  final String title;
  final String description;
  final String restaurantName;
  final String restaurantId;
  final String? categoryName; // null = tất cả món
  final double discountPercent; // VD: 20 = giảm 20%
  final double? maxDiscount;    // giảm tối đa x đồng
  final int totalQuantity;
  final int usedQuantity;
  final DateTime expiredAt;
  final String? imageUrl;

  const Voucher({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.restaurantName,
    required this.restaurantId,
    this.categoryName,
    required this.discountPercent,
    this.maxDiscount,
    required this.totalQuantity,
    required this.usedQuantity,
    required this.expiredAt,
    this.imageUrl,
  });

  // Còn lại bao nhiêu
  int get remainingQuantity => totalQuantity - usedQuantity;

  // Còn hiệu lực không
  bool get isValid =>
      remainingQuantity > 0 && expiredAt.isAfter(DateTime.now());

  // Số ngày còn lại
  int get daysLeft => expiredAt.difference(DateTime.now()).inDays;

  factory Voucher.fromJson(Map<String, dynamic> json) => Voucher(
        id: json['id']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        restaurantName: json['restaurantName']?.toString() ?? '',
        restaurantId: json['restaurantId']?.toString() ?? '',
        categoryName: json['categoryName']?.toString(),
        discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
        maxDiscount: (json['maxDiscount'] as num?)?.toDouble(),
        totalQuantity: (json['totalQuantity'] as num?)?.toInt() ?? 0,
        usedQuantity: (json['usedQuantity'] as num?)?.toInt() ?? 0,
        expiredAt: DateTime.tryParse(json['expiredAt']?.toString() ?? '') ??
            DateTime.now(),
        imageUrl: json['imageUrl']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'title': title,
        'description': description,
        'restaurantName': restaurantName,
        'restaurantId': restaurantId,
        'categoryName': categoryName,
        'discountPercent': discountPercent,
        'maxDiscount': maxDiscount,
        'totalQuantity': totalQuantity,
        'usedQuantity': usedQuantity,
        'expiredAt': expiredAt.toIso8601String(),
        'imageUrl': imageUrl,
      };
}

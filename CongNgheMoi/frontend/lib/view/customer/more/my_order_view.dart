import 'package:flutter/material.dart';

import '../../../common/color_extension.dart';
import '../../../common/globs.dart';
import '../../../common/service_call.dart';
import '../../../common_widget/round_button.dart';
import '../menu/all_reviews_view.dart';
import 'area_orders_view.dart';
import 'checkout_view.dart';
import 'review_order_view.dart';

// ─────────────────────────────────────────────
// MÀN HÌNH GIỎ HÀNG
// ─────────────────────────────────────────────
class MyOrderView extends StatefulWidget {
  const MyOrderView({super.key});

  @override
  State<MyOrderView> createState() => _MyOrderViewState();
}

class _MyOrderViewState extends State<MyOrderView> {
  late Future<Map<String, dynamic>> cartFuture;
  bool isRemoving = false;

  @override
  void initState() {
    super.initState();
    cartFuture = _loadCart();
  }

  Future<Map<String, dynamic>> _loadCart() async {
    try {
      final response =
          await ServiceCall.fetchGet(SVKey.svCustomerCart, isToken: true);
      if (response is Map<String, dynamic> && response['success'] == true) {
        final items = response['data'] as List? ?? [];
        final tongTien = response['tongTien'] ?? 0;

        final mappedItems = items.whereType<Map>().map((item) {
          final gia =
              double.tryParse(item['giaTien']?.toString() ?? '0') ?? 0;
          final sl = (item['soLuong'] as num?)?.toInt() ?? 1;
          return <String, dynamic>{
            'dishId': item['maMonAn'],
            'dishName': item['tenMonAn'] ?? 'Món ăn',
            'quantity': sl,
            'lineTotal': gia * sl,
            'canteenName': item['tenGianHang'] ?? '',
          };
        }).toList();

        return {'items': mappedItems, 'totalAmount': tongTien};
      }
    } catch (e) {
      debugPrint('Load cart error: $e');
    }
    return {'items': [], 'totalAmount': 0};
  }

  List<Map<String, dynamic>> _cartItems(Map<String, dynamic> cart) {
    final items = cart['items'] as List? ?? [];
    return items
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  Future<void> _refresh() async {
    final newFuture = _loadCart();
    setState(() => cartFuture = newFuture);
    await newFuture;
  }

  Future<void> _removeItem(dynamic dishId) async {
    final parsedId = int.tryParse(dishId?.toString() ?? '');
    if (parsedId == null || parsedId <= 0 || isRemoving) return;

    setState(() => isRemoving = true);
    try {
      await ServiceCall.fetchDelete(SVKey.svCartRemove(parsedId),
          isToken: true);
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => isRemoving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.white,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: cartFuture,
          builder: (context, snapshot) {
            final cart = snapshot.data ?? <String, dynamic>{};
            final items = _cartItems(cart);
            final totalAmount = _toDouble(cart['totalAmount']);

            return RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===== Header =====
                      Row(
                        children: [
                          IconButton(
                            onPressed: () =>
                                Navigator.pushNamedAndRemoveUntil(
                                    context, 'Home', (_) => false),
                            icon: Image.asset('assets/img/btn_back.png',
                                width: 20, height: 20),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Giỏ hàng',
                              style: TextStyle(
                                color: TColor.primaryText,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),



                      const SizedBox(height: 20),

                      // ===== Danh sách món =====
                      Text(
                        'Các món đã thêm vào giỏ của bạn.',
                        style: TextStyle(
                            color: TColor.secondaryText, fontSize: 13),
                      ),
                      const SizedBox(height: 18),

                      if (snapshot.connectionState ==
                          ConnectionState.waiting)
                        const Center(
                            child: Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator()))
                      else if (items.isEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 36),
                          child: Column(
                            children: [
                              Icon(Icons.shopping_cart_outlined,
                                  color: TColor.secondaryText, size: 64),
                              const SizedBox(height: 12),
                              Text(
                                'Giỏ hàng đang trống.',
                                style: TextStyle(
                                    color: TColor.primaryText,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Thêm món ăn rồi quay lại đây để thanh toán.',
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(color: TColor.secondaryText),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: TColor.textfield,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['dishName']?.toString() ??
                                              '',
                                          style: TextStyle(
                                              color: TColor.primaryText,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item['canteenName']
                                                  ?.toString() ??
                                              '',
                                          style: TextStyle(
                                              color: TColor.secondaryText,
                                              fontSize: 12),
                                        ),
                                        Text(
                                          'x${item['quantity'] ?? 1}  ·  ${_toDouble(item['lineTotal']).toStringAsFixed(0)} đ',
                                          style: TextStyle(
                                              color: TColor.primaryText,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: isRemoving
                                        ? null
                                        : () =>
                                            _removeItem(item['dishId']),
                                    icon: Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.red.shade300),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                      if (items.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Tổng tiền',
                                style: TextStyle(
                                    color: TColor.primaryText,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                            Text(
                              '${totalAmount.toStringAsFixed(0)} đ',
                              style: TextStyle(
                                  color: TColor.primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        RoundButton(
                          title: 'Tiến hành đặt hàng',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CheckoutView()),
                          ),
                        ),
                      ],
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


// MÀN HÌNH LỊCH SỬ ĐƠN HÀNG (có filter tabs)
// ─────────────────────────────────────────────
class OrderHistoryView extends StatefulWidget {
  final String? initialFilter;
  final bool isPushed;
  const OrderHistoryView({super.key, this.initialFilter, this.isPushed = false});

  @override
  State<OrderHistoryView> createState() => _OrderHistoryViewState();
}

class _OrderHistoryViewState extends State<OrderHistoryView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> ordersFuture;

  final List<_TabDef> _tabs = const [
    _TabDef('Tất cả', null),
    _TabDef('Đang ghép', 'choGhepDon'),
    _TabDef('Chờ giao', 'choGiaoHang'),
    _TabDef('Đã giao', 'daGiao'),
    _TabDef('Đã hủy', 'daHuy'),
  ];

  @override
  void initState() {
    super.initState();
    // Xác định tab ban đầu dựa trên initialFilter, mặc định là 1 (Đang ghép)
    int initialIndex = 1;
    if (widget.initialFilter != null) {
      final idx =
          _tabs.indexWhere((t) => t.status == widget.initialFilter);
      if (idx >= 0) initialIndex = idx;
    }
    _tabController = TabController(
        length: _tabs.length, vsync: this, initialIndex: initialIndex);
    ordersFuture = _loadMyOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadMyOrders() async {
    try {
      final response =
          await ServiceCall.fetchGet(SVKey.svOrderMy, isToken: true);
      if (response is Map && response['success'] == true) {
        final data = response['data'] as List? ?? [];
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (e) {
      debugPrint('Load orders error: $e');
    }
    return [];
  }

  Future<void> _refresh() async {
    setState(() => ordersFuture = _loadMyOrders());
    await ordersFuture;
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'choGhepDon':
        return 'Đang ghép đơn';
      case 'dangChuanBi':
        return 'Đang chuẩn bị';
      case 'choGiaoHang':
        return 'Chờ giao hàng';
      case 'dangGiao':
        return 'Đang giao';
      case 'daGiao':
        return 'Đã giao';
      case 'daHuy':
        return 'Đã hủy';
      default:
        return s ?? '';
    }
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'choGhepDon':
        return const Color(0xFFFF7043);
      case 'dangChuanBi':
        return Colors.blue;
      case 'choGiaoHang':
        return Colors.teal;
      case 'dangGiao':
        return Colors.green;
      case 'daGiao':
        return Colors.green.shade800;
      case 'daHuy':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _cancelOrder(dynamic orderId) async {
    final id = int.tryParse(orderId?.toString() ?? '');
    if (id == null) return;
    try {
      await ServiceCall.fetchPost(
        SVKey.svOrderMyCancel(id),
        isToken: true,
        body: {'reason': 'CUSTOMER_CANCELLED'},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Đã hủy đơn hàng.'),
            backgroundColor: Colors.green),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Column(
          children: [
            // ── AppBar ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (widget.isPushed) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushNamedAndRemoveUntil(context, 'Home', (_) => false);
                      }
                    },
                    icon: Image.asset('assets/img/btn_back.png',
                        width: 20, height: 20),
                  ),
                  Expanded(
                    child: Text(
                      'Lịch sử đơn hàng',
                      style: TextStyle(
                          color: TColor.primaryText,
                          fontSize: 20,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: _refresh,
                    icon: Icon(Icons.refresh_rounded, color: TColor.primary),
                  ),
                ],
              ),
            ),


            // ── Tab Bar ──
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: TColor.primary,
                indicatorWeight: 3,
                labelColor: TColor.primary,
                unselectedLabelColor: TColor.secondaryText,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontSize: 13),
                tabs: _tabs
                    .map((t) => Tab(text: t.label))
                    .toList(),
              ),
            ),

            // ── Tab Content ──
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: ordersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allOrders = snapshot.data ?? [];

                  return TabBarView(
                    controller: _tabController,
                    children: _tabs.map((tab) {
                      final orders = tab.status == null
                          ? allOrders
                          : allOrders
                              .where((o) =>
                                  o['trangThaiDonHang']?.toString() ==
                                  tab.status)
                              .toList();

                      return _OrderList(
                        orders: orders,
                        statusLabel: _statusLabel,
                        statusColor: _statusColor,
                        onCancel: _cancelOrder,
                        onRefresh: _refresh,
                        onReview: (orderId, danhSachMon) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReviewOrderView(
                                maDonHang: orderId,
                                danhSachMon: danhSachMon,
                              ),
                            ),
                          ).then((_) => _refresh());
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabDef {
  final String label;
  final String? status;
  const _TabDef(this.label, this.status);
}

// ─────────────────────────────────────────────
// WIDGET: Danh sách đơn hàng
// ─────────────────────────────────────────────
class _OrderList extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final String Function(String?) statusLabel;
  final Color Function(String?) statusColor;
  final Future<void> Function(dynamic) onCancel;
  final Future<void> Function() onRefresh;
  final void Function(dynamic orderId, String? danhSachMon) onReview;

  const _OrderList({
    required this.orders,
    required this.statusLabel,
    required this.statusColor,
    required this.onCancel,
    required this.onRefresh,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                color: Colors.grey.shade300, size: 72),
            const SizedBox(height: 14),
            const Text(
              'Chưa có đơn hàng nào.',
              style:
                  TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          final order = orders[index];
          final status = order['trangThaiDonHang']?.toString();
          final maDon = order['maDonHang'];
          final sColor = statusColor(status);

          Widget orderCard = Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─ Status bar top ─
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: sColor.withValues(alpha: 0.08),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Icon(_statusIcon(status),
                          color: sColor, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel(status),
                        style: TextStyle(
                            color: sColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(
                        '#${maDon ?? ''}',
                        style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 11),
                      ),
                    ],
                  ),
                ),

                // ─ Content ─
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Địa chỉ
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              color: TColor.primary, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${order['tenToaNha'] ?? ''} · P.${order['tenPhong'] ?? ''}',
                              style: TextStyle(
                                  color: TColor.primaryText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Món ăn
                      Text(
                        order['danhSachMon']?.toString() ?? '',
                        style: TextStyle(
                            color: TColor.secondaryText,
                            fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Tổng tiền
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${double.tryParse(order['tongTien']?.toString() ?? '0')?.toStringAsFixed(0)} đ',
                            style: TextStyle(
                                color: TColor.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800),
                          ),
                          if (status == 'choGhepDon')
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                backgroundColor:
                                    Colors.red.withValues(alpha: 0.08),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(20)),
                              ),
                              onPressed: () => onCancel(maDon),
                              child: Text(
                                'Hủy đơn',
                                style: TextStyle(
                                    color: Colors.red.shade600,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          if (status == 'daGiao') ...[  
                            Builder(builder: (_) {
                              final tongMon = (order['tongMon'] as num?)?.toInt() ?? 0;
                              final soMonDaDanhGia = (order['soMonDaDanhGia'] as num?)?.toInt() ?? 0;
                              final daDanhGia = tongMon > 0 && soMonDaDanhGia >= tongMon;
                              if (daDanhGia) {
                                // Đã đánh giá → xem đánh giá tại AllReviewsView
                                final maMonAn = (order['maMonAnDauTien'] as num?)?.toInt();
                                final tenMon = order['tenMonAnDauTien']?.toString()
                                    ?? order['danhSachMon']?.toString()
                                    ?? 'Món ăn';
                                return GestureDetector(
                                  onTap: () {
                                    if (maMonAn != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AllReviewsView(
                                            dishId: maMonAn,
                                            dishName: tenMon,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle_rounded,
                                            color: Colors.grey.shade400,
                                            size: 13),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Xem đánh giá',
                                          style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              return _ReviewButton(
                                onTap: () => onReview(
                                  maDon,
                                  order['danhSachMon']?.toString(),
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          if (status == 'choGhepDon') {
            return GestureDetector(
              onTap: () {
                final maToaNha = int.tryParse(order['maToaNha']?.toString() ?? '');
                if (maToaNha != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AreaOrdersView(
                        toaNha: maToaNha,
                        tenToaNha: order['tenToaNha']?.toString() ?? '',
                      ),
                    ),
                  );
                }
              },
              child: orderCard,
            );
          }
          
          return orderCard;
        },
      ),
    );
  }

  IconData _statusIcon(String? s) {
    switch (s) {
      case 'choGhepDon':
        return Icons.access_time_rounded;
      case 'dangChuanBi':
        return Icons.restaurant_rounded;
      case 'choGiaoHang':
        return Icons.local_shipping_outlined;
      case 'dangGiao':
        return Icons.delivery_dining_rounded;
      case 'daGiao':
        return Icons.check_circle_rounded;
      case 'daHuy':
        return Icons.cancel_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }
}

// ─────────────────────────────────────────────
// WIDGET: Nút Đánh giá kiểu Shopee
// ─────────────────────────────────────────────
class _ReviewButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ReviewButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEE4D2D), Color(0xFFFF6B4A)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEE4D2D).withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.star_rounded, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text(
              'Đánh giá',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}
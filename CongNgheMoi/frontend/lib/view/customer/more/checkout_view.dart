import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../common/color_extension.dart';
import '../../../common/globs.dart';
import '../../../common/service_call.dart';
import '../../../common_widget/round_button.dart';
import '../../../common_widget/round_textfield.dart';
import 'area_orders_view.dart';

class CheckoutView extends StatefulWidget {
  final Map<String, dynamic>? cartData;
  const CheckoutView({super.key, this.cartData});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  late Future<Map<String, dynamic>> cartFuture;

  late TextEditingController txtName;

  List<Map<String, dynamic>> buildings = [];
  List<Map<String, dynamic>> rooms = [];

  int? selectedBuildingId;
  int? selectedRoomId;
  bool isSubmitting = false;
  bool isLoadingAddress = true;
  List<Map<String, dynamic>> areaOrdersPreview = [];
  bool isLoadingAreaOrders = false;

  @override
  void initState() {
    super.initState();
    final payload = ServiceCall.userPayload;
    // Backend lưu họ tên trong 'hoTen', login_view normalize thêm 'name'
    final userName = (payload['hoTen'] ?? payload['fullName'] ?? payload[KKey.name] ?? '').toString().trim();
    txtName = TextEditingController(text: userName);
    cartFuture = widget.cartData != null
        ? Future.value(widget.cartData!)
        : _loadCart();
    _loadAddressData();
  }

  Future<void> _loadAddressData() async {
    try {
      final response = await ServiceCall.fetchGet(SVKey.svAddress, isToken: true);
      if (response is Map && response['success'] == true) {
        final data = response['data'] as Map? ?? {};
        if (mounted) {
          setState(() {
            buildings = (data['buildings'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
            rooms = (data['rooms'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
            isLoadingAddress = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoadingAddress = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingAddress = false);
    }
  }

  Future<void> _loadAreaOrders(int maToaNha) async {
    setState(() {
      isLoadingAreaOrders = true;
      areaOrdersPreview = [];
    });
    try {
      final response = await ServiceCall.fetchGet(
        SVKey.svOrderAreaOrders,
        queryParameters: {'maToaNha': maToaNha.toString()},
        isToken: true,
      );
      if (response is Map && response['success'] == true) {
        final data = response['data'] as List? ?? [];
        if (mounted) {
          setState(() {
            areaOrdersPreview = data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Load area orders error: $e');
    } finally {
      if (mounted) setState(() => isLoadingAreaOrders = false);
    }
  }

  @override
  void dispose() {
    txtName.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadCart() async {
    try {
      final response = await ServiceCall.fetchGet(SVKey.svCustomerCart, isToken: true);
      if (response is Map<String, dynamic> && response['success'] == true) {
        final rawItems = response['data'] as List? ?? [];
        final tongTien = response['tongTien'] ?? 0;

        final mappedItems = rawItems.whereType<Map>().map((item) {
          final gia = double.tryParse(item['giaTien']?.toString() ?? '0') ?? 0;
          final sl = (item['soLuong'] as num?)?.toInt() ?? 1;
          return <String, dynamic>{
            'dishId'     : item['maMonAn'],
            'dishName'   : item['tenMonAn'] ?? 'Món ăn',
            'canteenId'  : item['maGianHang'],
            'canteenName': item['tenGianHang'] ?? '',
            'quantity'   : sl,
            'lineTotal'  : gia * sl,
            'giaTien'    : gia,
          };
        }).toList();

        return {'items': mappedItems, 'totalAmount': tongTien};
      }
    } catch (e) {
      debugPrint('Checkout load cart error: $e');
    }
    return {'items': [], 'totalAmount': 0};
  }

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  List<Map<String, dynamic>> _cartItems(Map<String, dynamic> cart) {
    final items = cart['items'] as List? ?? [];
    return items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> _submitOrder(Map<String, dynamic> cart) async {
    final items = _cartItems(cart);
    final name = txtName.text.trim();

    if (items.isEmpty) {
      _snack('Giỏ hàng đang trống.');
      return;
    }
    if (name.isEmpty) {
      _snack('Vui lòng nhập họ tên.');
      return;
    }
    if (selectedBuildingId == null) {
      _snack('Vui lòng chọn tòa nhà.');
      return;
    }
    if (selectedRoomId == null) {
      _snack('Vui lòng chọn phòng học.');
      return;
    }

    setState(() => isSubmitting = true);

    try {
      Globs.showHUD(status: 'Đang gửi đơn...');

      // Kiểm tra có đơn ở tòa nhà khác không
      final myOrdersRes = await ServiceCall.fetchGet(SVKey.svOrderMy, isToken: true);
      if (myOrdersRes is Map && myOrdersRes['success'] == true && myOrdersRes['data'] != null) {
        final List orders = myOrdersRes['data'] as List;
        for (var o in orders) {
          if (o['trangThaiDonHang'] == 'choGhepDon' && o['maToaNha'] != selectedBuildingId) {
            Globs.hideHUD();
            if (!mounted) return;
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Thông báo', style: TextStyle(fontWeight: FontWeight.bold)),
                content: Text('Bạn đang có đơn ở ${o['tenToaNha'] ?? ''}. Vui lòng hủy đơn đang ghép hoặc đặt đơn ở cùng khu vực để được ghép chung.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Đóng', style: TextStyle(color: TColor.primary)),
                  )
                ],
              ),
            );
            return;
          }
        }
      }

      double tongTien = 0;
      for (final item in items) {
        tongTien += _toDouble(item['lineTotal']);
      }

      final orderItems = items.map((item) => {
            'maMonAn': item['dishId'],
            'soLuong': item['quantity'] ?? 1,
            'giaTien': _toDouble(item['giaTien']),
          }).toList();

      final response = await ServiceCall.fetchPost(
        SVKey.svOrderCheckout,
        isToken: true,
        body: {
          'maToaNha'  : selectedBuildingId,
          'maPhong'   : selectedRoomId,
          'tongTien': tongTien,
          'items'   : orderItems,
        },
      );

      if (response is! Map || response['success'] != true) {
        final msg = response is Map
            ? (response['message'] ?? 'Đặt hàng thất bại.')
            : 'Đặt hàng thất bại. Vui lòng thử lại.';
        throw msg.toString();
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AreaOrdersView(
            toaNha: selectedBuildingId!,
            tenToaNha: buildings.firstWhere((b) => b['maToaNha'] == selectedBuildingId, orElse: () => {})['tenToaNha']?.toString() ?? '',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _snack(error.toString());
    } finally {
      Globs.hideHUD();
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.white,
      body: FutureBuilder<Map<String, dynamic>>(
        future: cartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final cart = snapshot.data ?? <String, dynamic>{};
          final items = _cartItems(cart);
          final totalAmount = _toDouble(cart['totalAmount']);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Image.asset('assets/img/btn_back.png', width: 20, height: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Xác nhận đặt hàng',
                        style: TextStyle(
                          color: TColor.primaryText,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ---- Thông tin giao hàng ----
                  _sectionTitle('Thông tin giao hàng'),
                  const SizedBox(height: 12),

                  RoundTextfield(
                    hintText: 'Họ và tên người nhận',
                    controller: txtName,
                    left: Icon(Icons.person_outline, color: TColor.secondaryText, size: 20),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      // Dropdown Tòa nhà
                      Expanded(
                        child: Container(
                          height: 55,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: TColor.textfield,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.business_outlined, color: TColor.secondaryText, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: selectedBuildingId,
                                    isExpanded: true,
                                    hint: Text('Tòa nhà', style: TextStyle(color: TColor.placeholder, fontSize: 14)),
                                    borderRadius: BorderRadius.circular(20),
                                    menuMaxHeight: 300,
                                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: TColor.primaryText),
                                    items: buildings.map((b) => DropdownMenuItem<int>(
                                      value: b['maToaNha'] as int,
                                      child: Text(b['tenToaNha'].toString(), style: TextStyle(color: TColor.primaryText, fontSize: 14)),
                                    )).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        if (selectedBuildingId != val) {
                                          selectedBuildingId = val;
                                          if (val != null) _loadAreaOrders(val);
                                        }
                                        // Chiều thuận: Khi đổi tòa nhà, reset phòng học nếu phòng đó ko thuộc tòa nhà mới
                                        if (selectedRoomId != null) {
                                          final currentRoom = rooms.firstWhere((r) => r['maPhong'] == selectedRoomId, orElse: () => {});
                                          if (currentRoom['maToaNha'] != val) {
                                            selectedRoomId = null;
                                          }
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Dropdown Phòng học
                      Expanded(
                        child: Container(
                          height: 55,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: TColor.textfield,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.meeting_room_outlined, color: TColor.secondaryText, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: selectedRoomId,
                                    isExpanded: true,
                                    hint: Text('Phòng học', style: TextStyle(color: TColor.placeholder, fontSize: 14)),
                                    borderRadius: BorderRadius.circular(20),
                                    menuMaxHeight: 300,
                                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: TColor.primaryText),
                                    items: rooms.where((r) => selectedBuildingId == null || r['maToaNha'] == selectedBuildingId).map((r) => DropdownMenuItem<int>(
                                      value: r['maPhong'] as int,
                                      child: Text(r['tenPhong'].toString(), style: TextStyle(color: TColor.primaryText, fontSize: 14)),
                                    )).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        selectedRoomId = val;
                                        // Chiều nghịch: Tự động gán tòa nhà tương ứng nếu người dùng chưa chọn tòa nhà
                                        if (selectedBuildingId == null && val != null) {
                                          final matchedRoom = rooms.firstWhere((r) => r['maPhong'] == val, orElse: () => {});
                                          if (matchedRoom.isNotEmpty) {
                                            selectedBuildingId = matchedRoom['maToaNha'] as int;
                                            _loadAreaOrders(selectedBuildingId!);
                                          }
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildAreaOrdersPreview(),

                  // ---- Danh sách món ----
                  _sectionTitle('Món trong giỏ (${items.length} món)'),
                  const SizedBox(height: 12),

                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text('Giỏ hàng trống.', style: TextStyle(color: TColor.secondaryText)),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: TColor.textfield,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => Divider(
                          indent: 16, endIndent: 16,
                          color: TColor.secondaryText.withOpacity(0.3),
                          height: 1,
                        ),
                        itemBuilder: (_, index) {
                          final item = items[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['dishName']?.toString() ?? '',
                                        style: TextStyle(
                                          color: TColor.primaryText,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item['canteenName'] ?? '',
                                        style: TextStyle(color: TColor.secondaryText, fontSize: 12),
                                      ),
                                      Text(
                                        'x${item['quantity']}',
                                        style: TextStyle(color: TColor.secondaryText, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${_toDouble(item['lineTotal']).toStringAsFixed(0)} đ',
                                  style: TextStyle(
                                    color: TColor.primaryText,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Tổng tiền
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tổng tiền',
                          style: TextStyle(color: TColor.primaryText, fontSize: 15, fontWeight: FontWeight.w700)),
                      Text(
                        '${totalAmount.toStringAsFixed(0)} đ',
                        style: TextStyle(color: TColor.primary, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Nút đặt hàng
                  RoundButton(
                    title: isSubmitting ? 'Đang đặt hàng...' : 'Đặt hàng',
                    onPressed: isSubmitting ? () {} : () => _submitOrder(cart),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: TextStyle(color: TColor.primaryText, fontSize: 16, fontWeight: FontWeight.w800),
      );

  Widget _buildAreaOrdersPreview() {
    if (selectedBuildingId == null) return const SizedBox();
    if (isLoadingAreaOrders) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (areaOrdersPreview.isEmpty) return const SizedBox();

    final previewList = areaOrdersPreview.take(3).toList();
    final currentBuildingName = buildings.firstWhere((b) => b['maToaNha'] == selectedBuildingId, orElse: () => {})['tenToaNha']?.toString() ?? selectedBuildingId.toString();
    int currentUserId = ServiceCall.userPayload['maTaiKhoan'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _sectionTitle('Gợi ý đơn ghép tòa $currentBuildingName')),
            if (areaOrdersPreview.length > 3)
              TextButton(
                onPressed: () => _showAllAreaOrders(currentBuildingName),
                child: Text('Xem tất cả', style: TextStyle(color: TColor.primary, fontSize: 13, fontWeight: FontWeight.w700)),
              )
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: TColor.textfield,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.transparent), // for clip
          ),
          clipBehavior: Clip.antiAlias,
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 0),
            itemCount: previewList.length,
            separatorBuilder: (_, __) => Divider(
              indent: 16, endIndent: 16,
              color: TColor.secondaryText.withOpacity(0.3),
              height: 1,
            ),
            itemBuilder: (_, index) {
              final order = previewList[index];
              bool isMyOrder = order['maTaiKhoan'] == currentUserId;
              
              return Container(
                color: isMyOrder ? Colors.green.withOpacity(0.15) : Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (order['tenKhach']?.toString() ?? 'Khách') + (isMyOrder ? ' (Đơn của bạn)' : ''),
                            style: TextStyle(
                              color: isMyOrder ? Colors.green.shade700 : TColor.primaryText, 
                              fontSize: 14, 
                              fontWeight: FontWeight.w700
                            ),
                          ),
                        ),
                        Text(
                          'P.${order['tenPhong'] ?? ''}',
                          style: TextStyle(color: isMyOrder ? Colors.green.shade700 : TColor.secondaryText, fontSize: 12, fontWeight: isMyOrder ? FontWeight.w600 : FontWeight.normal),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order['danhSachMon']?.toString() ?? '',
                      style: TextStyle(color: TColor.secondaryText, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _showAllAreaOrders(String buildingName) {
    int currentUserId = ServiceCall.userPayload['maTaiKhoan'] as int? ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('Đơn chờ ghép tại Tòa $buildingName', style: TextStyle(color: TColor.primaryText, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: areaOrdersPreview.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final order = areaOrdersPreview[index];
                    bool isMyOrder = order['maTaiKhoan'] == currentUserId;
                    
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isMyOrder ? Colors.green.withOpacity(0.15) : TColor.textfield,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isMyOrder ? Colors.green.withOpacity(0.5) : Colors.transparent),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  (order['tenKhach']?.toString() ?? 'Khách') + (isMyOrder ? ' (Đơn của bạn)' : ''),
                                  style: TextStyle(
                                    color: isMyOrder ? Colors.green.shade700 : TColor.primaryText, 
                                    fontSize: 15, 
                                    fontWeight: FontWeight.w700
                                  ),
                                ),
                              ),
                              Text(
                                'P.${order['tenPhong'] ?? ''}',
                                style: TextStyle(color: isMyOrder ? Colors.green.shade700 : TColor.secondaryText, fontSize: 13, fontWeight: isMyOrder ? FontWeight.w600 : FontWeight.normal),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            order['danhSachMon']?.toString() ?? '',
                            style: TextStyle(color: TColor.secondaryText, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
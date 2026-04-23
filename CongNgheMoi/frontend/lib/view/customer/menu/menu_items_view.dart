import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common_widget/round_textfield.dart';

import '../../../common/globs.dart';
import '../../../common/service_call.dart';
import '../../../common_widget/menu_item_row.dart';
import '../more/my_order_view.dart';
import 'item_details_view.dart';

class MenuItemsView extends StatefulWidget {
  final Map mObj;
  const MenuItemsView({super.key, required this.mObj});

  @override
  State<MenuItemsView> createState() => _MenuItemsViewState();
}

class _MenuItemsViewState extends State<MenuItemsView> {
  final TextEditingController txtSearch = TextEditingController();
  late Future<List<Map<String, dynamic>>> itemsFuture;
  int _cartCount = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    txtSearch.addListener(_onSearchChanged);
    itemsFuture = _loadItems();
    _loadCartCount();
  }

  @override
  void dispose() {
    txtSearch.removeListener(_onSearchChanged);
    txtSearch.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = txtSearch.text);
  }

  Future<void> _loadCartCount() async {
    try {
      final res = await ServiceCall.fetchGet(SVKey.svCustomerCart, isToken: true);
      if (res is Map && res['success'] == true) {
        final items = res['data'] as List? ?? [];
        final count = items.fold<int>(0, (sum, item) {
          final sl = (item['soLuong'] as num?)?.toInt() ?? 0;
          return sum + sl;
        });
        if (mounted) setState(() => _cartCount = count);
      }
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> _loadItems() async {
    // Lấy canteenId từ object gian hàng truyền vào
    // canteenId có thể là 'canteenId' (nếu truyền từ dish) hoặc 'id' (nếu truyền từ gian hàng)
    final canteenId = (widget.mObj['canteenId'] ?? widget.mObj['id'])?.toString() ?? '';
    if (canteenId.isEmpty) return [];

    try {
      final response = await ServiceCall.fetchGet(
        SVKey.svDishesByCanteen(canteenId),
        isToken: true,
      );
      final raw = response is Map ? (response['data'] ?? response) : response;
      final list = raw as List? ?? [];

      return list.cast<Map>().map((item) {
        final map = Map<String, dynamic>.from(item);
        final price = map['giaTien'] ?? map['price'];
        return {
          'imageUrl'  : map['hinhAnh']?.toString() ?? map['imageUrl']?.toString(),
          'name'      : map['tenMonAn']?.toString() ?? map['name']?.toString() ?? '',
          'rate'      : price?.toString() ?? '0',
          'rating'    : '',
          'type'      : map['tenDanhMuc']?.toString() ?? map['categoryName']?.toString() ?? '',
          'food_type' : widget.mObj['name']?.toString() ?? '',
          'dishId'    : map['maMonAn'] ?? map['id'],
          'canteenId' : map['maGianHang'] ?? map['canteenId'],
          'price'     : price,
          'description': map['moTa']?.toString() ?? map['description']?.toString() ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('MenuItems load error: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 46),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Image.asset("assets/img/btn_back.png",
                          width: 20, height: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.mObj["name"]?.toString() ?? '',
                        style: TextStyle(
                            color: TColor.primaryText,
                            fontSize: 20,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                    // Badge giỏ hàng
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const MyOrderView()),
                            );
                            _loadCartCount();
                          },
                          icon: Image.asset(
                            "assets/img/shopping_cart.png",
                            width: 25,
                            height: 25,
                          ),
                        ),
                        if (_cartCount > 0)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: TColor.primary,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                  minWidth: 18, minHeight: 18),
                              child: Text(
                                _cartCount > 99 ? '99+' : '$_cartCount',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: RoundTextfield(
                  hintText: "Tìm món ăn...",
                  controller: txtSearch,
                  left: Container(
                    alignment: Alignment.center,
                    width: 30,
                    child: Image.asset(
                      "assets/img/search.png",
                      width: 20,
                      height: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: itemsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final allItems = snapshot.data ?? [];
                  final query = _searchQuery.trim().toLowerCase();
                  final items = query.isEmpty
                      ? allItems
                      : allItems.where((item) {
                          final name = item['name']?.toString().toLowerCase() ?? '';
                          return name.contains(query);
                        }).toList();

                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.restaurant_menu_outlined,
                                color: TColor.secondaryText, size: 56),
                            const SizedBox(height: 12),
                            Text(
                              allItems.isEmpty
                                  ? 'Gian hàng chưa có món ăn nào.'
                                  : 'Không tìm thấy món phù hợp.',
                              style: TextStyle(color: TColor.secondaryText),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: items.length,
                    itemBuilder: ((context, index) {
                      final mObj = items[index];
                      return MenuItemRow(
                        mObj: mObj,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ItemDetailsView(dishObj: mObj),
                            ),
                          );
                          _loadCartCount(); // refresh badge sau khi thêm món
                        },
                      );
                    }),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

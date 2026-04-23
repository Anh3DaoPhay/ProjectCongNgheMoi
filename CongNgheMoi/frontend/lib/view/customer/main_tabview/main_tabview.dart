import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common/globs.dart';
import 'package:food_delivery/common/service_call.dart';
import 'package:food_delivery/common_widget/tab_button.dart';

import '../home/home_view.dart';
import '../more/my_order_view.dart';
import '../more/more_view.dart';
import '../profile/profile_view.dart';

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  int selctTab = 2;
  PageStorageBucket storageBucket = PageStorageBucket();
  Widget selectPageView = const HomeView();
  int _cartCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCartCount();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageStorage(bucket: storageBucket, child: selectPageView),
      backgroundColor: const Color(0xfff5f5f5),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterDocked,
      floatingActionButton: SizedBox(
        width: 60,
        height: 60,
        child: FloatingActionButton(
          onPressed: () {
            if (selctTab != 2) {
              selctTab = 2;
              selectPageView = const HomeView();
            }
            if (mounted) {
              setState(() {});
            }
          },
          shape: const CircleBorder(),
          backgroundColor: selctTab == 2 ? TColor.primary : TColor.placeholder,
          child: Image.asset(
            "assets/img/tab_home.png",
            width: 30,
            height: 30,
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        surfaceTintColor: TColor.white,
        shadowColor: Colors.black,
        elevation: 1,
        notchMargin: 12,
        shape: const CircularNotchedRectangle(),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TabButton(
                  title: "Đơn hàng",
                  icon: "assets/img/tab_menu.png",
                  onTap: () {
                    if (selctTab != 0) {
                      selctTab = 0;
                      selectPageView = const OrderHistoryView();
                    }
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  isSelected: selctTab == 0),
              // Tab Giỏ hàng với badge
              GestureDetector(
                onTap: () async {
                  if (selctTab != 1) {
                    selctTab = 1;
                    selectPageView = const MyOrderView();
                  }
                  if (mounted) setState(() {});
                  await Future.delayed(const Duration(milliseconds: 500));
                  _loadCartCount();
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Image.asset(
                          "assets/img/shopping_cart.png",
                          width: 25,
                          height: 25,
                          color: selctTab == 1
                              ? TColor.primary
                              : TColor.placeholder,
                        ),
                        if (_cartCount > 0)
                          Positioned(
                            right: -6,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: TColor.primary,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                  minWidth: 16, minHeight: 16),
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
                    const SizedBox(height: 2),
                    Text(
                      "Giỏ hàng",
                      style: TextStyle(
                        color: selctTab == 1
                            ? TColor.primary
                            : TColor.placeholder,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 40, height: 40),

              TabButton(
                  title: "Profile",
                  icon: "assets/img/tab_profile.png",
                  onTap: () {
                    if (selctTab != 3) {
                      selctTab = 3;
                      selectPageView = const ProfileView();
                    }
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  isSelected: selctTab == 3),
              TabButton(
                  title: "More",
                  icon: "assets/img/tab_more.png",
                  onTap: () {
                    if (selctTab != 4) {
                      selctTab = 4;
                      selectPageView = const MoreView();
                    }
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  isSelected: selctTab == 4),
            ],
          ),
        ),
      ),
    );
  }
}

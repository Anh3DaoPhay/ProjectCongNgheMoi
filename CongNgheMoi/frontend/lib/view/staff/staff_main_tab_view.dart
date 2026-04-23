import 'package:flutter/material.dart';
import '../../common/color_extension.dart';
import 'staff_kds_view.dart';
import 'staff_menu_view.dart';
import 'staff_more_view.dart';
import 'staff_orders_view.dart';
import 'staff_store_view.dart';

class StaffMainTabView extends StatefulWidget {
  const StaffMainTabView({super.key});

  @override
  State<StaffMainTabView> createState() => _StaffMainTabViewState();
}

class _StaffMainTabViewState extends State<StaffMainTabView> {
  int _selectedTab = 0;

  final List<Widget> _pages = const [
    StaffOrdersView(),
    StaffKDSView(),
    StaffMenuView(),
    StaffStoreView(),
    StaffMoreView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedTab,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 12,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedTab,
          onTap: (i) => setState(() => _selectedTab = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: TColor.primary,
          unselectedItemColor: const Color(0xFFAAAAAA),
          selectedLabelStyle: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.kitchen_outlined),
              activeIcon: Icon(Icons.kitchen),
              label: 'Prepare',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu_outlined),
              activeIcon: Icon(Icons.restaurant_menu_rounded),
              label: 'Menu',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront_rounded),
              label: 'Store',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz_rounded),
              activeIcon: Icon(Icons.more_horiz_rounded),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}

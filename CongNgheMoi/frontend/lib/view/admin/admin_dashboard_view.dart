// lib/view/admin/admin_dashboard_view.dart
import 'package:flutter/material.dart';
import '../../common/globs.dart';
import '../../common/service_call.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  Map<String, dynamic> _stats = {};
  List<dynamic> _recentOrders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ServiceCall.fetchGet(SVKey.svAdminDashboard, isToken: true);
      if (res is Map && res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>? ?? {};
        setState(() {
          _stats = Map<String, dynamic>.from(data['stats'] as Map? ?? {});
          _recentOrders = data['recentOrders'] as List? ?? [];
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header
                    const Text('📊 Dashboard Admin',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
                    const Text('Tổng quan hệ thống Food Delivery',
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 20),

                    // Stats Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.6,
                      children: [
                        _StatCard('Tài khoản', '${_stats['tongTaiKhoan'] ?? 0}', Icons.people_rounded, const Color(0xFF6C63FF)),
                        _StatCard('Gian hàng', '${_stats['tongGianHang'] ?? 0}', Icons.store_rounded, const Color(0xFF2ECC71)),
                        _StatCard('Đơn hàng', '${_stats['tongDonHang'] ?? 0}', Icons.receipt_long_rounded, const Color(0xFFFF6B35)),
                        _StatCard('Doanh thu',
                            '${_fmtMoney(_toDouble(_stats['tongDoanhThu']))}đ',
                            Icons.attach_money_rounded, const Color(0xFFE74C3C)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Recent orders
                    const Text('Đơn hàng gần đây',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    ..._recentOrders.map((o) => _OrderTile(order: Map<String, dynamic>.from(o as Map))),
                  ],
                ),
        ),
      ),
    );
  }

  double _toDouble(dynamic v) => (v is num) ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0;
  String _fmtMoney(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ])),
      ]),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderTile({required this.order});

  Color _statusColor(String s) {
    switch (s) {
      case 'daGiao': return Colors.green;
      case 'dangChuanBi': return Colors.orange;
      case 'daHuy': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = order['trangThaiDonHang']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('#${order['maDonHang']} — ${order['tenKhach'] ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          Text('${order['tenToaNha'] ?? ''} · ${_fmtMoney((order['tongTien'] as num?)?.toDouble() ?? 0)}đ',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor(status).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(status, style: TextStyle(fontSize: 10, color: _statusColor(status), fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  String _fmtMoney(double v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}K' : v.toStringAsFixed(0);
}

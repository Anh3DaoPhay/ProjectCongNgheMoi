// lib/view/admin/manage_users_view.dart
import 'package:flutter/material.dart';
import '../../common/globs.dart';
import '../../common/service_call.dart';

class ManageUsersView extends StatefulWidget {
  const ManageUsersView({super.key});
  @override
  State<ManageUsersView> createState() => _ManageUsersViewState();
}

class _ManageUsersViewState extends State<ManageUsersView> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Map<int, List<Map<String, dynamic>>> _usersByRole = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ServiceCall.fetchGet(SVKey.svAdminUsers, isToken: true);
      if (res is Map && res['success'] == true) {
        final all = (res['data'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)).toList();
        final Map<int, List<Map<String, dynamic>>> grouped = {};
        for (final u in all) {
          final role = (u['maVaiTro'] as num?)?.toInt() ?? 1;
          grouped.putIfAbsent(role, () => []).add(u);
        }
        setState(() => _usersByRole = grouped);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleBan(Map<String, dynamic> user) async {
    final current = (user['trangThai'] as num?)?.toInt() ?? 1;
    final newStatus = current == 1 ? 0 : 1;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(newStatus == 0 ? '🔒 Khóa tài khoản' : '🔓 Mở tài khoản'),
        content: Text('Bạn có chắc muốn ${newStatus == 0 ? "khóa" : "mở"} tài khoản "${user['hoTen']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: newStatus == 0 ? Colors.red : Colors.green),
            onPressed: () => Navigator.pop(context, true),
            child: Text(newStatus == 0 ? 'Khóa' : 'Mở', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ServiceCall.fetchPut(SVKey.svAdminUpdateUser(user['maTaiKhoan']),
          isToken: true, body: {'trangThai': newStatus});
      _load();
    } catch (_) {}
  }

  Widget _buildList(int role) {
    final users = _usersByRole[role] ?? [];
    if (users.isEmpty) return const Center(child: Text('Không có tài khoản nào.'));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final u = users[i];
        final isActive = (u['trangThai'] as num?)?.toInt() == 1;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isActive ? Colors.blue.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
              child: Text(
                (u['hoTen']?.toString() ?? '?').substring(0, 1).toUpperCase(),
                style: TextStyle(fontWeight: FontWeight.w800, color: isActive ? Colors.blue : Colors.red),
              ),
            ),
            title: Text(u['hoTen']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: Text('${u['tenDangNhap'] ?? ''}  •  ${u['email'] ?? 'Chưa có email'}',
                style: const TextStyle(fontSize: 12)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(isActive ? 'Active' : 'Banned',
                    style: TextStyle(fontSize: 10, color: isActive ? Colors.green : Colors.red, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _toggleBan(u),
                child: Icon(isActive ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                    color: isActive ? Colors.red : Colors.green, size: 22),
              ),
            ]),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('👥 Quản lý Tài khoản', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: const Color(0xFF6C63FF),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF6C63FF),
          tabs: [
            Tab(text: 'Khách hàng (${_usersByRole[1]?.length ?? 0})'),
            Tab(text: 'Nhân viên (${_usersByRole[2]?.length ?? 0})'),
            Tab(text: 'Admin (${_usersByRole[3]?.length ?? 0})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtrl,
              children: [_buildList(1), _buildList(2), _buildList(3)],
            ),
    );
  }
}

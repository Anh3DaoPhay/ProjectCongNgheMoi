// lib/view/admin/manage_stores_view.dart
import 'package:flutter/material.dart';
import '../../common/globs.dart';
import '../../common/service_call.dart';

class ManageStoresView extends StatefulWidget {
  const ManageStoresView({super.key});
  @override
  State<ManageStoresView> createState() => _ManageStoresViewState();
}

class _ManageStoresViewState extends State<ManageStoresView> {
  List<Map<String, dynamic>> _stores = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ServiceCall.fetchGet(SVKey.svAdminStores, isToken: true);
      if (res is Map && res['success'] == true) {
        setState(() => _stores = (res['data'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)).toList());
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleStatus(Map<String, dynamic> store) async {
    final current = (store['trangThai'] as num?)?.toInt() ?? 1;
    final newStatus = current == 1 ? 0 : 1;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(newStatus == 0 ? '🔒 Khóa gian hàng' : '🔓 Mở gian hàng'),
        content: Text('Bạn có chắc muốn ${newStatus == 0 ? "khóa" : "mở"} gian hàng "${store['tenGianHang']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
              child: Text(newStatus == 0 ? 'Khóa' : 'Mở')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ServiceCall.fetchPut(SVKey.svAdminUpdateStore(store['maGianHang']),
          isToken: true, body: {'trangThai': newStatus});
      _load();
    } catch (_) {}
  }

  void _showCreateDialog() {
    final tenGHCtrl    = TextEditingController();
    final moTaCtrl     = TextEditingController();
    final usernameCtrl = TextEditingController();
    final passCtrl     = TextEditingController();
    final hoTenCtrl    = TextEditingController();
    final emailCtrl    = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🏪 Tạo Gian hàng mới', style: TextStyle(fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _field(tenGHCtrl,    'Tên gian hàng *'),
            _field(moTaCtrl,     'Mô tả'),
            const Divider(height: 20),
            const Text('Tài khoản Nhân viên', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
            _field(usernameCtrl, 'Tên đăng nhập *'),
            _field(passCtrl,     'Mật khẩu *', obscure: true),
            _field(hoTenCtrl,    'Họ tên nhân viên'),
            _field(emailCtrl,    'Email'),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
            onPressed: () async {
              if (tenGHCtrl.text.isEmpty || usernameCtrl.text.isEmpty || passCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin bắt buộc (*).')));
                return;
              }
              try {
                final res = await ServiceCall.fetchPost(SVKey.svAdminStores, isToken: true, body: {
                  'tenGianHang': tenGHCtrl.text.trim(),
                  'moTa': moTaCtrl.text.trim(),
                  'tenDangNhap': usernameCtrl.text.trim(),
                  'matKhau': passCtrl.text,
                  'hoTen': hoTenCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                });
                if (!context.mounted) return;
                Navigator.pop(context);
                if (res is Map && res['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Tạo gian hàng thành công!')));
                  _load();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res is Map ? (res['message'] ?? 'Lỗi') : 'Lỗi')));
                }
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: const Text('Tạo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, {bool obscure = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(
          controller: ctrl,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('🏪 Quản lý Gian hàng', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
          IconButton(onPressed: _showCreateDialog, icon: const Icon(Icons.add_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _stores.isEmpty
                  ? const Center(child: Text('Chưa có gian hàng nào.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _stores.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final s = _stores[i];
                        final isActive = (s['trangThai'] as num?)?.toInt() == 1;
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: isActive ? const Color(0xFF2ECC71).withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                              child: Icon(Icons.store_rounded, color: isActive ? const Color(0xFF2ECC71) : Colors.red),
                            ),
                            title: Text(s['tenGianHang']?.toString() ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('👤 ${s['tenChuQuan'] ?? 'Chưa có'}  •  ${s['email'] ?? ''}',
                                  style: const TextStyle(fontSize: 12)),
                              Text('📦 ${s['tongDon'] ?? 0} đơn  •  💰 ${_fmtMoney((s['doanhThu'] as num?)?.toDouble() ?? 0)}đ',
                                  style: const TextStyle(fontSize: 12)),
                            ]),
                            trailing: Switch(
                              value: isActive,
                              activeColor: const Color(0xFF2ECC71),
                              onChanged: (_) => _toggleStatus(s),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  String _fmtMoney(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

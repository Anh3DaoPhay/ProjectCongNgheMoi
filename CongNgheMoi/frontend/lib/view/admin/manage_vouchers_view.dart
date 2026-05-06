// lib/view/admin/manage_vouchers_view.dart
import 'package:flutter/material.dart';
import '../../common/globs.dart';
import '../../common/service_call.dart';

class ManageVouchersView extends StatefulWidget {
  const ManageVouchersView({super.key});
  @override
  State<ManageVouchersView> createState() => _ManageVouchersViewState();
}

class _ManageVouchersViewState extends State<ManageVouchersView> {
  List<Map<String, dynamic>> _vouchers = [];
  List<Map<String, dynamic>> _stores   = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final [vRes, sRes] = await Future.wait([
        ServiceCall.fetchGet(SVKey.svAdminVouchers, isToken: true),
        ServiceCall.fetchGet(SVKey.svAdminStores, isToken: true),
      ]);
      if (vRes is Map && vRes['success'] == true)
        _vouchers = (vRes['data'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (sRes is Map && sRes['success'] == true)
        _stores   = (sRes['data'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _deleteVoucher(dynamic id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🗑️ Xóa voucher'),
        content: const Text('Bạn có chắc muốn xóa voucher này? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ServiceCall.fetchDelete(SVKey.svAdminDeleteVoucher(id), isToken: true);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Đã xóa voucher.')));
      _load();
    } catch (_) {}
  }

  Future<void> _toggleActive(Map<String, dynamic> v) async {
    final current = v['isActive'];
    final newVal  = (current is bool) ? !current : current == 1 ? 0 : 1;
    try {
      await ServiceCall.fetchPut(SVKey.svAdminUpdateVoucher(v['id']),
          isToken: true, body: {'isActive': newVal is bool ? (newVal ? 1 : 0) : newVal});
      _load();
    } catch (_) {}
  }

  void _showCreateDialog() {
    final codeCtrl    = TextEditingController();
    final titleCtrl   = TextEditingController();
    final descCtrl    = TextEditingController();
    final percentCtrl = TextEditingController();
    final maxUseCtrl  = TextEditingController();
    final endCtrl     = TextEditingController();
    int? selectedStoreId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
        title: const Text('🎟️ Tạo Voucher mới', style: TextStyle(fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _field(codeCtrl,    'Mã voucher * (VD: WELCOME20)'),
            _field(titleCtrl,   'Tiêu đề *'),
            _field(descCtrl,    'Mô tả'),
            _field(percentCtrl, 'Giảm (%) *', type: TextInputType.number),
            _field(maxUseCtrl,  'Giới hạn lượt (để trống = không giới hạn)', type: TextInputType.number),
            _field(endCtrl,     'Ngày kết thúc (YYYY-MM-DD)'),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              value: selectedStoreId,
              decoration: InputDecoration(
                labelText: 'Áp dụng cho gian hàng (để trống = toàn sàn)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Toàn sàn')),
                ..._stores.map((s) => DropdownMenuItem<int?>(
                  value: (s['maGianHang'] as num?)?.toInt(),
                  child: Text(s['tenGianHang']?.toString() ?? ''),
                )),
              ],
              onChanged: (v) => setD(() => selectedStoreId = v),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
            onPressed: () async {
              if (codeCtrl.text.isEmpty || titleCtrl.text.isEmpty || percentCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin bắt buộc (*).')));
                return;
              }
              try {
                final res = await ServiceCall.fetchPost(SVKey.svAdminVouchers, isToken: true, body: {
                  'code'           : codeCtrl.text.trim().toUpperCase(),
                  'title'          : titleCtrl.text.trim(),
                  'description'    : descCtrl.text.trim(),
                  'discountPercent': double.tryParse(percentCtrl.text) ?? 0,
                  'maxUses'        : maxUseCtrl.text.isEmpty ? null : int.tryParse(maxUseCtrl.text),
                  'endsAt'         : endCtrl.text.isEmpty ? null : endCtrl.text.trim(),
                  'maGianHang'     : selectedStoreId,
                });
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (res is Map && res['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Tạo voucher thành công!')));
                  _load();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res is Map ? (res['message'] ?? 'Lỗi') : 'Lỗi')));
                }
              } catch (e) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: const Text('Tạo', style: TextStyle(color: Colors.white)),
          ),
        ],
      )),
    );
  }

  Widget _field(TextEditingController c, String hint, {TextInputType? type}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(
          controller: c,
          keyboardType: type,
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
        title: const Text('🎟️ Quản lý Voucher', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
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
              child: _vouchers.isEmpty
                  ? const Center(child: Text('Chưa có voucher nào.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _vouchers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final v = _vouchers[i];
                        final isActive = v['isActive'] == true || v['isActive'] == 1;
                        final scope = v['canteenName'] != null ? '🏪 ${v['canteenName']}' : '🌐 Toàn sàn';
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isActive ? const Color(0xFF6C63FF).withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text('-${(v['discountPercent'] as num?)?.toInt() ?? 0}%',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12,
                                        color: isActive ? const Color(0xFF6C63FF) : Colors.grey)),
                              ),
                            ),
                            title: Text('${v['code']} — ${v['title']}',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(scope, style: const TextStyle(fontSize: 11)),
                              Text('Đã lưu: ${v['soLuotLuu'] ?? 0}  •  Giới hạn: ${v['maxUses'] ?? '∞'}',
                                  style: const TextStyle(fontSize: 11)),
                            ]),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              Switch(
                                value: isActive,
                                activeColor: const Color(0xFF6C63FF),
                                onChanged: (_) => _toggleActive(v),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                onPressed: () => _deleteVoucher(v['id']),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

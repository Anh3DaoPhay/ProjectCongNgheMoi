// lib/view/staff/staff_ship_view.dart
// Tab Ship — Màn hình Giao hàng (Delivery Pool)
import 'dart:async';
import 'package:flutter/material.dart';
import '../../common/color_extension.dart';
import '../../common/globs.dart';
import '../../common/service_call.dart';

class StaffShipView extends StatefulWidget {
  const StaffShipView({super.key});

  @override
  State<StaffShipView> createState() => _StaffShipViewState();
}

class _StaffShipViewState extends State<StaffShipView> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _readyItems = [];
  Map<String, dynamic>? _activeTrip;   // chuyến đang giao (null = không có)
  bool _loading = true;
  bool _starting = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final [readyRes, tripRes] = await Future.wait([
        ServiceCall.fetchGet(SVKey.svStaffReadyItems, isToken: true),
        ServiceCall.fetchGet(SVKey.svStaffActiveTrip, isToken: true),
      ]);
      if (!mounted) return;
      setState(() {
        if (readyRes is Map && readyRes['success'] == true)
          _readyItems = (readyRes['data'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (tripRes is Map && tripRes['success'] == true)
          _activeTrip = tripRes['data'] != null ? Map<String, dynamic>.from(tripRes['data'] as Map) : null;
      });
    } catch (_) {}
    if (mounted && !silent) setState(() => _loading = false);
  }

  Future<void> _startTrip() async {
    setState(() => _starting = true);
    try {
      final res = await ServiceCall.fetchPost(SVKey.svStaffStartTrip, isToken: true);
      if (res is Map && res['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🚀 ${res['message'] ?? 'Đã bắt đầu chuyến giao!'}'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _load();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res is Map ? (res['message'] ?? 'Lỗi') : 'Lỗi')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _completeTrip(int tripId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('✅ Hoàn tất chuyến giao', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Bạn đã giao tất cả món trong chuyến này cho khách chưa?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Chưa xong')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hoàn tất!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      Globs.showHUD(status: 'Đang cập nhật...');
      final res = await ServiceCall.fetchPut(SVKey.svStaffCompleteTrip(tripId), isToken: true);
      Globs.hideHUD();
      if (res is Map && res['success'] == true) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Hoàn tất! Khách đã nhận hàng.'), backgroundColor: Colors.green),
        );
        await _load();
      }
    } catch (e) {
      Globs.hideHUD();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('🚚 Tab Ship — Giao hàng',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1A1A1A))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [IconButton(icon: Icon(Icons.refresh_rounded, color: TColor.primary), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _activeTrip != null
                  ? _buildActiveTripView()
                  : _buildReadyPoolView(),
            ),
    );
  }

  // ── View 1: Đang có chuyến giao ──────────────────────────────────────────────
  Widget _buildActiveTripView() {
    final tripId  = (_activeTrip!['maNhomGiaoHang'] as num?)?.toInt() ?? 0;
    final items   = (_activeTrip!['items'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

    // Nhóm theo tòa nhà + phòng
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final item in items) {
      final key = '${item['tenToaNha'] ?? ''} — ${item['tenPhong'] ?? ''}';
      grouped.putIfAbsent(key, () => []).add(item);
    }

    return Column(children: [
      // Banner chuyến đang giao
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        color: Colors.orange.shade50,
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.delivery_dining_rounded, color: Colors.orange, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Đang có chuyến giao hàng', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.orange)),
            Text('${items.length} phần ăn · ${grouped.length} địa điểm', style: const TextStyle(fontSize: 12, color: Colors.orange)),
          ])),
        ]),
      ),

      // Danh sách nhóm theo địa điểm
      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...grouped.entries.map((entry) => _buildLocationGroup(entry.key, entry.value)),
            const SizedBox(height: 80),
          ],
        ),
      ),

      // Nút Hoàn tất
      Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
            onPressed: () => _completeTrip(tripId),
            icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
            label: const Text('Hoàn tất chuyến giao', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    ]);
  }

  Widget _buildLocationGroup(String location, List<Map<String, dynamic>> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: TColor.primary.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(children: [
            Icon(Icons.location_on_rounded, color: TColor.primary, size: 18),
            const SizedBox(width: 6),
            Text(location, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: TColor.primary)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: TColor.primary, borderRadius: BorderRadius.circular(8)),
              child: Text('${items.length} món', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
        ...items.asMap().entries.map((e) {
          final i = e.value;
          final isLast = e.key == items.length - 1;
          return _buildDeliveryItemTile(i, isLast);
        }),
      ]),
    );
  }

  Widget _buildDeliveryItemTile(Map<String, dynamic> item, bool isLast) {
    final imgUrl = item['hinhAnh']?.toString() ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imgUrl.isNotEmpty
              ? Image.network('${SVKey.nodeUrl}/$imgUrl', width: 44, height: 44, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imgPlaceholder())
              : _imgPlaceholder(),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item['tenMonAn']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          Text('Khách: ${item['tenKhach'] ?? ''}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ])),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.delivery_dining_rounded, color: Colors.orange, size: 18),
        ),
      ]),
    );
  }

  // ── View 2: Quầy chờ giao (Delivery Pool) ────────────────────────────────────
  Widget _buildReadyPoolView() {
    if (_readyItems.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Column(children: [
              Icon(Icons.delivery_dining_rounded, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('Chưa có món nào sẵn sàng', style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Khi bếp hoàn thành món, chúng sẽ xuất hiện ở đây', style: TextStyle(color: Colors.grey.shade400, fontSize: 13), textAlign: TextAlign.center),
            ]),
          ),
        ],
      );
    }

    // Nhóm theo địa điểm
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final item in _readyItems) {
      final key = '${item['tenToaNha'] ?? 'Không rõ'} — ${item['tenPhong'] ?? ''}';
      grouped.putIfAbsent(key, () => []).add(item);
    }

    return Column(children: [
      // Banner quầy chờ
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        color: Colors.green.shade50,
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.kitchen_rounded, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Quầy chờ giao', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.green)),
            Text('${_readyItems.length} phần ăn · ${grouped.length} địa điểm đang chờ', style: const TextStyle(fontSize: 12, color: Colors.green)),
          ])),
        ]),
      ),

      // Danh sách
      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...grouped.entries.map((e) => _buildReadyGroup(e.key, e.value)),
            const SizedBox(height: 80),
          ],
        ),
      ),

      // Nút Bắt đầu giao
      Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: TColor.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
            onPressed: _starting ? null : _startTrip,
            icon: _starting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 22),
            label: Text(
              _starting ? 'Đang tạo chuyến...' : 'Bắt đầu đi giao (${_readyItems.length} món)',
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildReadyGroup(String location, List<Map<String, dynamic>> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.06), blurRadius: 10)],
      ),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(children: [
            const Icon(Icons.location_on_rounded, color: Colors.green, size: 16),
            const SizedBox(width: 6),
            Expanded(child: Text(location, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.green))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
              child: Text('${items.length} món', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
        ...items.asMap().entries.map((e) {
          final item = e.value;
          final isLast = e.key == items.length - 1;
          final imgUrl = item['hinhAnh']?.toString() ?? '';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imgUrl.isNotEmpty
                    ? Image.network('${SVKey.nodeUrl}/$imgUrl', width: 42, height: 42, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imgPlaceholder())
                    : _imgPlaceholder(),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['tenMonAn']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(item['tenKhach']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ])),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
              ),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _imgPlaceholder() => Container(
    width: 42, height: 42,
    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
    child: Icon(Icons.fastfood, color: Colors.grey.shade400, size: 20),
  );
}

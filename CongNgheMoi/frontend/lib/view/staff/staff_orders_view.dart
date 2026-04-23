import 'package:flutter/material.dart';
import '../../common/color_extension.dart';
import '../../common/globs.dart';
import '../../common/service_call.dart';

enum _OrderTab { pending, preparing, completed }

class StaffOrdersView extends StatefulWidget {
  const StaffOrdersView({super.key});

  @override
  State<StaffOrdersView> createState() => _StaffOrdersViewState();
}

class _StaffOrdersViewState extends State<StaffOrdersView> {
  _OrderTab _selectedTab = _OrderTab.pending;
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  final Set<int> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await ServiceCall.fetchGet(
        SVKey.svOrderStaffPending,
        isToken: true,
      );
      if (response is Map && response['success'] == true) {
        final data = response['data'] as List? ?? [];
        setState(() {
          _orders = data
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải đơn: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markReady(int maDonHang) async {
    if (_processingIds.contains(maDonHang)) return;
    setState(() => _processingIds.add(maDonHang));
    try {
      final response = await ServiceCall.fetchPut(
        SVKey.svOrderMarkReady(maDonHang),
        isToken: true,
      );
      if (!mounted) return;
      if (response is Map && response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã báo xong! Hệ thống sẽ kiểm tra nhóm giao hàng.'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  response?['message']?.toString() ?? 'Có lỗi xảy ra.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(maDonHang));
    }
  }

  Future<void> _startPreparing(int maDonHang) async {
    if (_processingIds.contains(maDonHang)) return;
    setState(() => _processingIds.add(maDonHang));
    try {
      final response = await ServiceCall.fetchPut(
        SVKey.svOrderStartPreparing(maDonHang),
        isToken: true,
      );
      if (!mounted) return;
      if (response is Map && response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã bắt đầu làm!'),
            backgroundColor: Colors.blue,
          ),
        );
        await _loadOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  response?['message']?.toString() ?? 'Có lỗi xảy ra.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(maDonHang));
    }
  }

  Future<void> _startPreparingGroup(List<int> orderIds, int maNhom) async {
    if (_processingIds.contains(-maNhom)) return;
    setState(() => _processingIds.add(-maNhom));
    try {
      for (int maDonHang in orderIds) {
        await ServiceCall.fetchPut(
          SVKey.svOrderStartPreparing(maDonHang),
          isToken: true,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã bắt đầu làm nhóm đơn!'),
          backgroundColor: Colors.blue,
        ),
      );
      await _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(-maNhom));
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    final filtered = _orders.where((o) {
      final status = o['trangThaiDonHang']?.toString().toLowerCase() ?? '';
      switch (_selectedTab) {
        case _OrderTab.pending:
          return ['pending', 'choxacnhan'].contains(status);
        case _OrderTab.preparing:
          return ['dangchuanbi', 'grouped', 'chogiao', 'chogiaohang', 'single_accepted', 'confirmed']
              .contains(status);
        case _OrderTab.completed:
          return ['delivered', 'dagiao'].contains(status);
      }
    }).toList();

    if (_selectedTab == _OrderTab.pending) {
      final Map<int, Map<String, dynamic>> groups = {};
      final List<Map<String, dynamic>> result = [];

      for (var o in filtered) {
        if (o['trangThaiDonHang'] == 'choXacNhan' && o['maNhomGiaoHang'] != null) {
          final maNhom = o['maNhomGiaoHang'] as int;
          if (!groups.containsKey(maNhom)) {
            groups[maNhom] = {
              'isGroup': true,
              'maNhomGiaoHang': maNhom,
              'toaNha': o['tenToaNha'] ?? o['toaNha'],
              'orderIds': <int>[],
              'dishes': <String>[],
              'tongTien': 0.0,
              'trangThaiDonHang': 'choXacNhan',
            };
          }
          
          groups[maNhom]!['orderIds'].add(o['maDonHang']);
          
          final num total = (o['tongTien'] ?? o['total'] ?? 0) as num;
          groups[maNhom]!['tongTien'] += total;
          
          final rawDishes = o['danhSachMon']?.toString() ?? '';
          if (rawDishes.isNotEmpty) {
            groups[maNhom]!['dishes'].addAll(rawDishes.split(',').map((s) => s.trim()));
          }
        } else {
          result.add(o);
        }
      }
      
      for (var group in groups.values) {
        final dishes = group['dishes'] as List<String>;
        final Map<String, int> dishCounts = {};
        for (var d in dishes) {
           final match = RegExp(r'(.*?)(?:\s+x(\d+))?$').firstMatch(d);
           if (match != null) {
             final name = match.group(1)?.trim() ?? d;
             final qty = int.tryParse(match.group(2) ?? '1') ?? 1;
             dishCounts[name] = (dishCounts[name] ?? 0) + qty;
           } else {
             dishCounts[d] = (dishCounts[d] ?? 0) + 1;
           }
        }
        final combinedDishes = dishCounts.entries.map((e) => '${e.key} x${e.value}').join(', ');
        group['danhSachMon'] = combinedDishes;
        result.add(group);
      }
      return result;
    }

    return filtered;
  }

  String _tabLabel(_OrderTab tab) {
    switch (tab) {
      case _OrderTab.pending:
        return 'Pending';
      case _OrderTab.preparing:
        return 'Preparing';
      case _OrderTab.completed:
        return 'Completed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOrders;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Staff Orders Management',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF1A1A1A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: TColor.primary),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          // Segmented Control
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: _OrderTab.values.map((tab) {
                  final isSelected = _selectedTab == tab;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = tab),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected ? TColor.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: TColor.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          _tabLabel(tab),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF888888),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Order list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, index) =>
                              _buildOrderCard(filtered[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(
            'Không có đơn nào',
            style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Kéo xuống để làm mới',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final isGroup = order['isGroup'] == true;
    final maDonHang = order['maDonHang'] as int? ?? 0;
    final maNhom = order['maNhomGiaoHang'] as int? ?? 0;
    
    final procId = isGroup ? -maNhom : maDonHang;
    final isProcessing = _processingIds.contains(procId);
    final isNew = _selectedTab == _OrderTab.pending;

    // Build header
    final headerText = isGroup 
        ? 'Đơn ghép nhóm #$maNhom - Tòa ${order['toaNha']}' 
        : '${order['tenKhach'] ?? 'Khách hàng'} - Floor ${order['tang'] ?? '--'}';

    final toaNha = order['toaNha']?.toString() ?? '';
    final phong = order['phong']?.toString() ?? '';

    // Parse dish list
    final rawDishes = order['danhSachMon']?.toString() ?? '';
    final dishes = rawDishes.isNotEmpty
        ? rawDishes.split(',').map((s) => s.trim()).toList()
        : <String>[];

    // Total
    final total = order['tongTien'] ?? order['total'] ?? 0;
    final totalStr =
        '${_formatCurrency(total)}đ';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    headerText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                if (isNew)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: TColor.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Mới',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),

          // Divider
          Container(height: 1, color: const Color(0xFFF0F0F0)),

          // Dish list
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: dishes.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: dishes
                        .map((d) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                d,
                                style: const TextStyle(
                                    fontSize: 14, color: Color(0xFF333333)),
                              ),
                            ))
                        .toList(),
                  )
                : Text(rawDishes,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF333333))),
          ),

          if (!isGroup && (toaNha.isNotEmpty || phong.isNotEmpty))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 13, color: TColor.secondaryText),
                  const SizedBox(width: 4),
                  Text(
                    'Tòa $toaNha · Phòng $phong',
                    style: TextStyle(
                        fontSize: 12, color: TColor.secondaryText),
                  ),
                ],
              ),
            ),

          // Total + Action
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Total: $totalStr',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                if (_selectedTab == _OrderTab.pending)
                  if (order['trangThaiDonHang'] == 'choXacNhan')
                    _buildActionButton(
                      label: isProcessing ? 'Đang xử lý...' : 'Bắt đầu làm',
                      isLoading: isProcessing,
                      onTap: isProcessing ? null : () {
                        if (isGroup) {
                          _startPreparingGroup(order['orderIds'] as List<int>, maNhom);
                        } else {
                          _startPreparing(maDonHang);
                        }
                      },
                      color: Colors.blue,
                    )
                  else
                    _buildActionButton(
                      label: isProcessing ? 'Đang xử lý...' : 'Đã chuẩn bị xong',
                      isLoading: isProcessing,
                      onTap: isProcessing ? null : () => _markReady(maDonHang),
                      color: Colors.green,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required bool isLoading,
    VoidCallback? onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: isLoading ? Colors.grey : (color ?? TColor.primary),
          borderRadius: BorderRadius.circular(10),
        ),
        child: isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
      ),
    );
  }

  String _formatCurrency(dynamic val) {
    final num v = (val is num) ? val : (num.tryParse(val?.toString() ?? '') ?? 0);
    return v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }
}

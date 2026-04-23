import 'package:flutter/material.dart';
import '../../common/color_extension.dart';
import '../../common/globs.dart';
import '../../common/service_call.dart';

class StaffKDSView extends StatefulWidget {
  const StaffKDSView({super.key});

  @override
  State<StaffKDSView> createState() => _StaffKDSViewState();
}

class _StaffKDSViewState extends State<StaffKDSView> {
  List<Map<String, dynamic>> _kdsItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKDSData();
  }

  Future<void> _loadKDSData() async {
    setState(() => _isLoading = true);
    try {
      final response = await ServiceCall.fetchGet(
        SVKey.svOrderStaffKDS,
        isToken: true,
      );
      if (response is Map && response['success'] == true) {
        final data = response['data'] as List? ?? [];
        setState(() {
          _kdsItems = data
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu KDS: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _swipeItem(int maMonAn, int index) async {
    // Remove locally first for instant UI response
    final item = _kdsItems[index];
    setState(() {
      _kdsItems.removeAt(index);
    });

    try {
      final response = await ServiceCall.fetchPut(
        SVKey.svOrderStaffKDSSwipe(maMonAn),
        isToken: true,
      );
      if (response is Map && response['success'] == true) {
        // Success, nothing to do
      } else {
        // Revert on failure
        if (mounted) {
          setState(() {
            _kdsItems.insert(index, item);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response?['message']?.toString() ?? 'Có lỗi xảy ra.')),
          );
        }
      }
    } catch (e) {
      // Revert on failure
      if (mounted) {
        setState(() {
          _kdsItems.insert(index, item);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Chuẩn bị món ăn',
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
            onPressed: _loadKDSData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _kdsItems.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadKDSData,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: _kdsItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _kdsItems[index];
                      final maMonAn = item['maMonAn'] as int? ?? 0;
                      return Dismissible(
                        key: ValueKey('kds_$maMonAn'),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          _swipeItem(maMonAn, index);
                        },
                        background: Container(
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        child: _buildItemCard(item),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.kitchen_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(
            'Chưa có món cần nấu',
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

  Widget _buildItemCard(Map<String, dynamic> item) {
    final tenMonAn = item['tenMonAn']?.toString() ?? 'Tên món';
    final hinhAnh = item['hinhAnh']?.toString();
    final tongSoLuong = item['tongSoLuong']?.toString() ?? '0';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TColor.primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: TColor.primary.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: hinhAnh != null && hinhAnh.isNotEmpty
                ? Image.network(
                    '${SVKey.nodeUrl}/$hinhAnh',
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                  )
                : _buildPlaceholderImage(),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tenMonAn,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.arrow_back_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Vuốt sang trái để hoàn thành',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Quantity Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: TColor.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'x$tongSoLuong',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 70,
      height: 70,
      color: Colors.grey.shade200,
      child: Icon(Icons.fastfood, color: Colors.grey.shade400, size: 30),
    );
  }
}

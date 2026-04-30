import 'package:flutter/material.dart';
import 'package:food_delivery/common/app_notification.dart';
import 'package:food_delivery/common/color_extension.dart';
import '../customer/voucher/voucher_model.dart';
import '../customer/voucher/voucher_service.dart';

// ─── Staff Voucher Management View ───────────────────────────────────────────
class StaffVoucherView extends StatefulWidget {
  const StaffVoucherView({super.key});

  @override
  State<StaffVoucherView> createState() => _StaffVoucherViewState();
}

class _StaffVoucherViewState extends State<StaffVoucherView> {
  // Chỉ lấy voucher của staff này (dùng mock restaurantId 'staff')
  static const _myRestaurantId = 'staff';

  List<Voucher> get _vouchers => VoucherService.instance
      .availableVouchers
      .where((v) => v.restaurantId == _myRestaurantId)
      .toList()
    ..addAll(VoucherService.instance
        .availableVouchers
        .where((v) => v.restaurantId != _myRestaurantId)
        .take(0)); // Chỉ hiện voucher của mình

  List<Voucher> get _myVouchers => VoucherService.instance.staffVouchers;

  void _openForm({Voucher? edit}) async {
    final result = await showModalBottomSheet<Voucher>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VoucherFormSheet(existing: edit),
    );
    if (result != null) {
      if (edit != null) {
        VoucherService.instance.updateStaffVoucher(result);
        AppNotification.show(context,
            message: 'Cập nhật voucher thành công!', type: NotifType.success);
      } else {
        VoucherService.instance.addStaffVoucher(result);
        AppNotification.show(context,
            title: 'Đã tạo voucher! 🎉',
            message: 'Voucher "${result.title}" đã được thêm.',
            type: NotifType.success);
      }
      setState(() {});
    }
  }

  Future<void> _delete(Voucher v) async {
    final ok = await AppNotification.confirm(context,
        title: 'Xoá voucher',
        message: 'Xoá voucher "${v.title}"?',
        confirmText: 'Xoá',
        cancelText: 'Huỷ');
    if (ok == true) {
      VoucherService.instance.deleteStaffVoucher(v.id);
      setState(() {});
      if (mounted) {
        AppNotification.show(context,
            message: 'Đã xoá voucher.', type: NotifType.info);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vouchers = _myVouchers;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Quản lý Voucher',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: TColor.primary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Tạo mới'),
              style: TextButton.styleFrom(foregroundColor: TColor.primary),
            ),
          ),
        ],
      ),
      body: vouchers.isEmpty
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.local_offer_outlined, size: 72, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('Chưa có voucher nào',
                    style: TextStyle(color: Colors.grey, fontSize: 15)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Tạo voucher đầu tiên'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColor.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ]),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vouchers.length,
              itemBuilder: (_, i) => _StaffVoucherCard(
                voucher: vouchers[i],
                onEdit: () => _openForm(edit: vouchers[i]),
                onDelete: () => _delete(vouchers[i]),
              ),
            ),
      floatingActionButton: vouchers.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(),
              backgroundColor: TColor.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tạo voucher', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
    );
  }
}

// ─── Voucher Card (Staff side) ────────────────────────────────────────────────
class _StaffVoucherCard extends StatelessWidget {
  final Voucher voucher;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StaffVoucherCard({
    required this.voucher,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = !voucher.isValid;
    final color = isExpired ? Colors.grey : TColor.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('-${voucher.discountPercent.toInt()}%',
                  style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(voucher.title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (isExpired)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Hết hạn',
                    style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 16, children: [
            _InfoChip(Icons.confirmation_number_outlined,
                'Mã: ${voucher.code}', color),
            _InfoChip(Icons.category_outlined,
                voucher.categoryName ?? 'Tất cả', Colors.blue),
            _InfoChip(Icons.people_outline_rounded,
                '${voucher.remainingQuantity}/${voucher.totalQuantity} lượt', Colors.green),
            _InfoChip(Icons.timer_outlined,
                isExpired ? 'Đã hết hạn' : 'Còn ${voucher.daysLeft} ngày',
                isExpired ? Colors.red : Colors.orange),
          ]),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Sửa', style: TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: TColor.primary,
                side: BorderSide(color: TColor.primary),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, size: 16),
              label: const Text('Xoá', style: TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]);
}

// ─── Create / Edit Form ───────────────────────────────────────────────────────
class _VoucherFormSheet extends StatefulWidget {
  final Voucher? existing;
  const _VoucherFormSheet({this.existing});

  @override
  State<_VoucherFormSheet> createState() => _VoucherFormSheetState();
}

class _VoucherFormSheetState extends State<_VoucherFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _discountCtrl;
  late TextEditingController _quantityCtrl;
  late TextEditingController _maxDiscountCtrl;
  DateTime? _expiredAt;
  String? _category;

  static const _categories = ['Tất cả', 'Cơm', 'Đồ uống', 'Trà sữa', 'Ăn vặt', 'Bún - Phở', 'Khác'];

  @override
  void initState() {
    super.initState();
    final v = widget.existing;
    _titleCtrl = TextEditingController(text: v?.title ?? '');
    _codeCtrl = TextEditingController(text: v?.code ?? _genCode());
    _discountCtrl = TextEditingController(text: v?.discountPercent.toStringAsFixed(0) ?? '');
    _quantityCtrl = TextEditingController(text: v?.totalQuantity.toString() ?? '');
    _maxDiscountCtrl = TextEditingController(text: v?.maxDiscount?.toStringAsFixed(0) ?? '');
    _expiredAt = v?.expiredAt;
    _category = v?.categoryName;
  }

  String _genCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ0123456789';
    return List.generate(8, (_) => chars[DateTime.now().microsecond % chars.length]).join();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _codeCtrl.dispose();
    _discountCtrl.dispose();
    _quantityCtrl.dispose();
    _maxDiscountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiredAt ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: TColor.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _expiredAt = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_expiredAt == null) {
      AppNotification.show(context,
          message: 'Vui lòng chọn ngày hết hạn!', type: NotifType.warning);
      return;
    }
    final v = widget.existing;
    final result = Voucher(
      id: v?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      code: _codeCtrl.text.trim().toUpperCase(),
      title: _titleCtrl.text.trim(),
      description: _titleCtrl.text.trim(),
      restaurantName: 'Gian hàng của tôi',
      restaurantId: 'staff',
      categoryName: (_category == null || _category == 'Tất cả') ? null : _category,
      discountPercent: double.parse(_discountCtrl.text.trim()),
      maxDiscount: _maxDiscountCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_maxDiscountCtrl.text.trim()),
      totalQuantity: int.parse(_quantityCtrl.text.trim()),
      usedQuantity: v?.usedQuantity ?? 0,
      expiredAt: _expiredAt!,
    );
    Navigator.pop(context, result);
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: TColor.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.6,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(children: [
              Expanded(
                child: Text(isEdit ? 'Sửa voucher' : 'Tạo voucher mới',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              ),
              IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context)),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(20),
                children: [
                  // Tiêu đề voucher
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: _dec('Tiêu đề voucher', hint: 'VD: Giảm 20% món cơm'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: 14),

                  // Mã voucher
                  TextFormField(
                    controller: _codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: _dec('Mã voucher', hint: 'VD: COM20'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: 14),

                  // % giảm + số lượng
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: _discountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _dec('% Giảm giá', hint: '10–100'),
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n == null || n <= 0 || n > 100) return 'Nhập 1–100';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _quantityCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _dec('Số lượng', hint: 'VD: 100'),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n <= 0) return 'Nhập > 0';
                          return null;
                        },
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),

                  // Giảm tối đa
                  TextFormField(
                    controller: _maxDiscountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _dec('Giảm tối đa (đ)', hint: 'Để trống = không giới hạn'),
                  ),
                  const SizedBox(height: 14),

                  // Loại voucher
                  DropdownButtonFormField<String>(
                    value: _category ?? 'Tất cả',
                    decoration: _dec('Áp dụng cho'),
                    borderRadius: BorderRadius.circular(14),
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v),
                  ),
                  const SizedBox(height: 14),

                  // Ngày hết hạn
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        Icon(Icons.calendar_today_rounded,
                            color: _expiredAt != null ? TColor.primary : Colors.grey, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          _expiredAt != null
                              ? 'Hết hạn: ${_expiredAt!.day}/${_expiredAt!.month}/${_expiredAt!.year}'
                              : 'Chọn ngày hết hạn *',
                          style: TextStyle(
                            color: _expiredAt != null ? TColor.primaryText : Colors.grey,
                            fontWeight: FontWeight.w500, fontSize: 14,
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColor.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(isEdit ? 'Cập nhật' : 'Tạo voucher',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

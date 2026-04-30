// lib/view/customer/voucher/home_voucher_section.dart
// Section voucher nằm giữa phần "Gợi ý bữa trưa" trên home screen.

import 'package:flutter/material.dart';
import 'package:food_delivery/common/app_notification.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'voucher_model.dart';
import 'voucher_service.dart';
import 'my_vouchers_view.dart';

class HomeVoucherSection extends StatefulWidget {
  const HomeVoucherSection({super.key});

  @override
  State<HomeVoucherSection> createState() => _HomeVoucherSectionState();
}

class _HomeVoucherSectionState extends State<HomeVoucherSection> {
  List<Voucher> get _vouchers {
    final all = VoucherService.instance.availableVouchers;
    // Chưa lưu lên đầu, đã lưu xuống cuối
    final uncollected = all.where((v) => !VoucherService.instance.hasCollected(v.id)).toList();
    final collected   = all.where((v) =>  VoucherService.instance.hasCollected(v.id)).toList();
    return [...uncollected, ...collected];
  }

  void _collect(Voucher v) {
    if (VoucherService.instance.hasCollected(v.id)) {
      AppNotification.show(context,
          message: 'Bạn đã thu thập voucher này rồi!', type: NotifType.warning);
      return;
    }
    VoucherService.instance.collectVoucher(v);
    setState(() {});
    AppNotification.show(context,
        title: 'Thu thập thành công! 🎉',
        message: 'Voucher "${v.title}" đã được lưu vào túi của bạn.',
        type: NotifType.success);
  }

  @override
  Widget build(BuildContext context) {
    if (_vouchers.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            const Expanded(
              child: Text('🎟️ Voucher hôm nay',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MyVouchersView()))
                  .then((_) => setState(() {})),
              child: Text('Xem tất cả',
                  style: TextStyle(color: TColor.primary, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        // Horizontal scroll list
        SizedBox(
          height: 145,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _vouchers.length,
            itemBuilder: (_, i) => _VoucherCard(
              voucher: _vouchers[i],
              collected: VoucherService.instance.hasCollected(_vouchers[i].id),
              onCollect: () => _collect(_vouchers[i]),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

// ─── Voucher Card (horizontal) ────────────────────────────────────────────────
class _VoucherCard extends StatelessWidget {
  final Voucher voucher;
  final bool collected;
  final VoidCallback onCollect;

  const _VoucherCard({
    required this.voucher,
    required this.collected,
    required this.onCollect,
  });

  Color get _bgColor {
    if (voucher.discountPercent >= 25) return const Color(0xFFFF6B35);
    if (voucher.discountPercent >= 15) return const Color(0xFF6C63FF);
    return const Color(0xFF2ECC71);
  }

  @override
  Widget build(BuildContext context) {
    final color = _bgColor;
    return Container(
      width: 230,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.75)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Stack(children: [
        // Decorative circle
        Positioned(right: -20, top: -20,
          child: Container(width: 90, height: 90,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1)))),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Discount badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('-${voucher.discountPercent.toInt()}%',
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w900, fontSize: 13)),
              ),
              const SizedBox(height: 6),
              Text(voucher.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 2),
              Text(voucher.restaurantName, maxLines: 1,
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
              const Spacer(),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Còn ${voucher.remainingQuantity} lượt',
                        style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    Text('HSD: ${voucher.daysLeft} ngày',
                        style: const TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                )),
                GestureDetector(
                  onTap: onCollect,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: collected ? Colors.white.withValues(alpha: 0.2) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(collected ? 'Đã lưu' : 'Thu thập',
                        style: TextStyle(
                          color: collected ? Colors.white : color,
                          fontWeight: FontWeight.w700, fontSize: 11,
                        )),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ]),
    );
  }
}

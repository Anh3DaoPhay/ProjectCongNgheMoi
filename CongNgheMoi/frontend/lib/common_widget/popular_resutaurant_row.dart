import 'package:flutter/material.dart';

import '../common/color_extension.dart';
import 'app_image_view.dart';

class PopularRestaurantRow extends StatelessWidget {
  final Map pObj;
  final VoidCallback onTap;
  const PopularRestaurantRow({super.key, required this.pObj, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              child: AppImageView(
                path: pObj["imageUrl"]?.toString() ?? pObj["image"]?.toString(),
                width: double.maxFinite,
                height: 200,
                fit: BoxFit.cover,
                placeholderAsset: 'assets/img/app_logo.png',
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pObj["name"]?.toString() ?? '',
                    style: TextStyle(
                        color: TColor.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    [
                      if ((pObj["type"]?.toString() ?? '').isNotEmpty)
                        pObj["type"]?.toString(),
                      if ((pObj["food_type"]?.toString() ?? '').isNotEmpty)
                        pObj["food_type"]?.toString(),
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: TColor.secondaryText, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

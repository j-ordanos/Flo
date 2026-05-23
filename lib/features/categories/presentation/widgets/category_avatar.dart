import 'package:flutter/material.dart';

import '../../../../core/utils/hex_color.dart';
import '../category_icons.dart';

/// Category badge: a rounded-square tinted tile with the category icon —
/// matches the design's `CatBadge` (radius = size * 0.32, tint bg, colored icon).
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    required this.iconKey,
    required this.colorHex,
    this.size = 40,
    super.key,
  });

  final String iconKey;
  final String colorHex;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(colorHex);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.18 : 0.14),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(iconForCategoryKey(iconKey), color: color, size: size * 0.5),
    );
  }
}

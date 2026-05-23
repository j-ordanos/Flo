import 'package:flutter/material.dart';

import '../../../../core/utils/hex_color.dart';
import '../category_icons.dart';

/// Round category badge: a tinted circle containing the category icon.
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    required this.iconKey,
    required this.colorHex,
    this.size = 44,
    super.key,
  });

  final String iconKey;
  final String colorHex;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(colorHex);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(iconForCategoryKey(iconKey), color: color, size: size * 0.5),
    );
  }
}

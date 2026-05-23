import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_shadows.dart';
import '../constants/app_spacing.dart';

/// Standard surface card: rounded, 1px border, faint shadow (light only),
/// optional tap ink — matches the design's bordered cards.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadii.card,
    this.onTap,
    this.color,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final border = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: border,
        boxShadow: AppShadows.card(theme.brightness),
      ),
      child: Material(
        color: color ?? theme.colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: border,
          side: BorderSide(
            color: dark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

/// Calculator-style keypad. Emits '0'-'9', '.', or 'back'.
class NumPad extends StatelessWidget {
  const NumPad({required this.onKey, this.showDecimal = true, super.key});

  final ValueChanged<String> onKey;
  final bool showDecimal;

  @override
  Widget build(BuildContext context) {
    final keys = [
      '1', '2', '3', '4', '5', '6', '7', '8', '9',
      showDecimal ? '.' : '', '0', 'back',
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.9,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      children: [
        for (final k in keys)
          if (k.isEmpty)
            const SizedBox.shrink()
          else
            _Key(label: k, onKey: onKey),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onKey});

  final String label;
  final ValueChanged<String> onKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final isBack = label == 'back';
    return Material(
      color: dark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onKey(label),
        child: Center(
          child: isBack
              ? const Icon(Icons.backspace_outlined,
                  size: 22, color: AppColors.danger)
              : Text(
                  label,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }
}

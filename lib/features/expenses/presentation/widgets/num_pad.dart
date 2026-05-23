import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';

/// Calculator-style numeric keypad. Emits digit taps (0-9) and backspace.
class NumPad extends StatelessWidget {
  const NumPad({required this.onDigit, required this.onBackspace, super.key});

  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2,
      mainAxisSpacing: AppSpacing.xs,
      crossAxisSpacing: AppSpacing.sm,
      children: [
        for (var i = 1; i <= 9; i++)
          _NumKey(label: '$i', onTap: () => onDigit(i)),
        const SizedBox.shrink(),
        _NumKey(label: '0', onTap: () => onDigit(0)),
        _NumKey(icon: Icons.backspace_outlined, onTap: onBackspace),
      ],
    );
  }
}

class _NumKey extends StatelessWidget {
  const _NumKey({required this.onTap, this.label, this.icon});

  final VoidCallback onTap;
  final String? label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.md),
      child: Center(
        child: icon != null
            ? Icon(icon, size: 26)
            : Text(
                label!,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}

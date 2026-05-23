import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';

/// A horizontal divider with a centered label.
class OrDivider extends StatelessWidget {
  const OrDivider({this.label = 'or', super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.hintColor, letterSpacing: 0.6),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

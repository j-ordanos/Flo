import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';

/// A horizontal divider with a centered "or" label.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text('or',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../constants/app_spacing.dart';

/// Skeleton list placeholder shown while data loads.
class ShimmerList extends StatelessWidget {
  const ShimmerList({this.itemCount = 6, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surfaceContainerHighest;
    final highlight = theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
        itemBuilder: (_, _) => Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: base, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, width: double.infinity, color: base),
                  const SizedBox(height: AppSpacing.sm),
                  Container(height: 10, width: 120, color: base),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

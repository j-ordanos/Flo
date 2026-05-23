import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/hex_color.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../categories/domain/entities/category.dart';

typedef CategorySlice = ({Category category, int cents});

/// Donut of spending by category with a centered total and a legend.
class CategoryDonut extends StatelessWidget {
  const CategoryDonut({required this.slices, super.key});

  final List<CategorySlice> slices;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = slices.fold<int>(0, (s, e) => s + e.cents);

    if (total == 0) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'No spending in this period',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 64,
                  sections: [
                    for (final s in slices)
                      PieChartSectionData(
                        value: s.cents.toDouble(),
                        color: hexToColor(s.category.colorHex),
                        radius: 26,
                        showTitle: false,
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(formatCents(total), style: theme.textTheme.titleLarge),
                  Text('total',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.hintColor)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            for (final s in slices)
              _Legend(
                color: hexToColor(s.category.colorHex),
                label: s.category.name,
                percent: s.cents / total,
              ),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    required this.percent,
  });

  final Color color;
  final String label;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text('$label  ${(percent * 100).round()}%',
            style: theme.textTheme.bodySmall),
      ],
    );
  }
}

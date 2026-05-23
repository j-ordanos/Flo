import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/hex_color.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../categories/domain/entities/category.dart';

typedef CategorySlice = ({Category category, int cents});

/// Donut of spending by category with a centered total. When [showLegend] is
/// true a wrapped color-key legend is appended below.
class CategoryDonut extends StatelessWidget {
  const CategoryDonut({
    required this.slices,
    this.size = 200,
    this.showLegend = true,
    super.key,
  });

  final List<CategorySlice> slices;
  final double size;
  final bool showLegend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = slices.fold<int>(0, (s, e) => s + e.cents);

    if (total == 0) {
      return SizedBox(
        height: size,
        child: Center(
          child: Text('No spending in this period',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
        ),
      );
    }

    final donut = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: size * 0.34,
              sections: [
                for (final s in slices)
                  PieChartSectionData(
                    value: s.cents.toDouble(),
                    color: hexToColor(s.category.colorHex),
                    radius: size * 0.13,
                    showTitle: false,
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('SPENT',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.hintColor, letterSpacing: 0.5)),
              Text(formatCents0(total), style: theme.textTheme.titleLarge),
            ],
          ),
        ],
      ),
    );

    if (!showLegend) return donut;

    return Column(
      children: [
        donut,
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

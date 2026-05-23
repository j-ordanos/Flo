import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

typedef MonthBar = ({String label, int cents});

/// Bar chart of spending over the last six months.
class MonthlyBarChart extends StatelessWidget {
  const MonthlyBarChart({required this.bars, super.key});

  final List<MonthBar> bars;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxCents = bars.fold<int>(0, (m, b) => b.cents > m ? b.cents : m);

    if (maxCents == 0) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text('No data yet',
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (maxCents / 100) * 1.2,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: const BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= bars.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(bars[i].label, style: theme.textTheme.labelSmall),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < bars.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: bars[i].cents / 100,
                    width: 16,
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

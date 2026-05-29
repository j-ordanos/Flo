import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/shimmer_list.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../providers/analytics_providers.dart';
import '../widgets/category_donut.dart';
import '../widgets/monthly_bar_chart.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: expensesAsync.when(
          loading: () => const ShimmerList(),
          error: (_, _) => const ErrorView(message: 'Could not load analytics.'),
          data: (all) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Insights',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: theme.hintColor)),
                            Text('Analytics',
                                style: theme.textTheme.headlineSmall),
                          ],
                        ),
                      ),
                      _CircleIconButton(
                        icon: Icons.ios_share,
                        onTap: () => _export(ref),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _Body(expenses: all)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _export(WidgetRef ref) async {
    final expenses = ref.read(expensesProvider).value ?? const [];
    final categories = ref.read(categoriesByIdProvider);
    await ref.read(csvExportServiceProvider).exportExpenses(expenses, categories);
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.expenses});

  final List<Expense> expenses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final period = ref.watch(analyticsPeriodProvider);
    final categoriesById = ref.watch(categoriesByIdProvider);

    // Analytics is about spending — exclude income.
    final spends =
        expenses.where((e) => e.type == TransactionType.expense).toList();
    final series = _series(period, spends);
    final periodTotal = series.fold<int>(0, (s, b) => s + b.cents);
    final trend = _trend(series);

    // Category slices for the current period window.
    final range = _rangeFor(period);
    final inPeriod = spends.where(
        (e) => !e.date.isBefore(range.start) && e.date.isBefore(range.end));
    final byCategory = <String, int>{};
    for (final e in inPeriod) {
      byCategory.update(e.categoryId, (v) => v + e.amountCents,
          ifAbsent: () => e.amountCents);
    }
    final slices = [
      for (final entry in byCategory.entries)
        if (categoriesById[entry.key] case final c?)
          (category: c, cents: entry.value),
    ]..sort((a, b) => b.cents.compareTo(a.cents));
    final total = slices.fold<int>(0, (s, x) => s + x.cents);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PeriodPill(
            value: period,
            onChanged: (p) => ref.read(analyticsPeriodProvider.notifier).set(p),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total this ${_periodWord(period)}',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.hintColor)),
                          const SizedBox(height: 2),
                          Text(formatCents(periodTotal),
                              style: theme.textTheme.headlineSmall),
                        ],
                      ),
                    ),
                    if (trend != null) _TrendPill(delta: trend),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                MonthlyBarChart(bars: series),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('By category', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    CategoryDonut(slices: slices, size: 148, showLegend: false),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        children: [
                          for (final s in slices.take(5))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _LegendRow(
                                label: s.category.name,
                                colorHex: s.category.colorHex,
                                percent: total == 0 ? 0 : s.cents / total,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () {
              final categories = ref.read(categoriesByIdProvider);
              ref
                  .read(csvExportServiceProvider)
                  .exportExpenses(expenses, categories);
            },
            icon: const Icon(Icons.ios_share, size: 18),
            label: Text('Export this ${_periodWord(period)} report'),
          ),
        ],
      ),
    );
  }
}

String _periodWord(AnalyticsPeriod p) => switch (p) {
      AnalyticsPeriod.day => 'day',
      AnalyticsPeriod.week => 'week',
      AnalyticsPeriod.month => 'month',
    };

/// Bars for the selected period: last 7 days / 7 weeks / 6 months.
List<MonthBar> _series(AnalyticsPeriod period, List<Expense> all) {
  final now = DateTime.now();
  int sumBetween(DateTime start, DateTime end) => all
      .where((e) => !e.date.isBefore(start) && e.date.isBefore(end))
      .fold<int>(0, (s, e) => s + e.amountCents);

  switch (period) {
    case AnalyticsPeriod.day:
      return [
        for (var i = 6; i >= 0; i--)
          () {
            final d = DateTime(now.year, now.month, now.day - i);
            return (
              label: DateFormat.E().format(d).substring(0, 1),
              cents: sumBetween(d, d.add(const Duration(days: 1))),
            );
          }(),
      ];
    case AnalyticsPeriod.week:
      return [
        for (var i = 6; i >= 0; i--)
          () {
            final monday = DateTime(now.year, now.month, now.day)
                .subtract(Duration(days: now.weekday - 1 + i * 7));
            return (
              label: 'W${6 - i + 1}',
              cents: sumBetween(monday, monday.add(const Duration(days: 7))),
            );
          }(),
      ];
    case AnalyticsPeriod.month:
      return [
        for (var i = 5; i >= 0; i--)
          () {
            final m = DateTime(now.year, now.month - i);
            return (
              label: DateFormat.MMM().format(m),
              cents: sumBetween(
                  DateTime(m.year, m.month), DateTime(m.year, m.month + 1)),
            );
          }(),
      ];
  }
}

/// Percentage change of the last bucket vs the previous one.
double? _trend(List<MonthBar> series) {
  if (series.length < 2) return null;
  final last = series.last.cents;
  final prev = series[series.length - 2].cents;
  if (prev == 0) return null;
  return (last - prev) / prev;
}

({DateTime start, DateTime end}) _rangeFor(AnalyticsPeriod period) {
  final now = DateTime.now();
  switch (period) {
    case AnalyticsPeriod.day:
      final start = DateTime(now.year, now.month, now.day);
      return (start: start, end: start.add(const Duration(days: 1)));
    case AnalyticsPeriod.week:
      final start = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      return (start: start, end: start.add(const Duration(days: 7)));
    case AnalyticsPeriod.month:
      return (
        start: DateTime(now.year, now.month),
        end: DateTime(now.year, now.month + 1),
      );
  }
}

class _PeriodPill extends StatelessWidget {
  const _PeriodPill({required this.value, required this.onChanged});

  final AnalyticsPeriod value;
  final ValueChanged<AnalyticsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
        borderRadius: BorderRadius.circular(AppRadii.button),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final p in AnalyticsPeriod.values)
            GestureDetector(
              onTap: () => onChanged(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: p == value ? theme.colorScheme.surface : null,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: p == value && !dark
                      ? const [
                          BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 3,
                              offset: Offset(0, 1))
                        ]
                      : null,
                ),
                child: Text(
                  switch (p) {
                    AnalyticsPeriod.day => 'Daily',
                    AnalyticsPeriod.week => 'Weekly',
                    AnalyticsPeriod.month => 'Monthly',
                  },
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: p == value
                        ? theme.colorScheme.onSurface
                        : theme.hintColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrendPill extends StatelessWidget {
  const _TrendPill({required this.delta});

  final double delta;

  @override
  Widget build(BuildContext context) {
    final down = delta <= 0;
    final color = down ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(down ? Icons.arrow_downward : Icons.arrow_upward,
              size: 12, color: color),
          const SizedBox(width: 4),
          Text('${(delta.abs() * 100).round()}%',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.label,
    required this.colorHex,
    required this.percent,
  });

  final String label;
  final String colorHex;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Color(int.parse('FF$colorHex', radix: 16)),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall),
        ),
        Text('${(percent * 100).round()}%',
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: CircleBorder(side: BorderSide(color: theme.dividerColor)),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 18, color: theme.colorScheme.onSurface),
        ),
      ),
    );
  }
}

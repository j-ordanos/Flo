import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/section_header.dart';
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
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            icon: const Icon(Icons.ios_share),
            onPressed: () => _export(ref),
          ),
        ],
      ),
      body: expensesAsync.when(
        loading: () => const ShimmerList(),
        error: (_, _) => const ErrorView(message: 'Could not load analytics.'),
        data: (all) => _Body(expenses: all),
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
    final period = ref.watch(analyticsPeriodProvider);
    final categoriesById = ref.watch(categoriesByIdProvider);
    final range = _rangeFor(period);

    final inPeriod = expenses
        .where((e) => !e.date.isBefore(range.start) && e.date.isBefore(range.end))
        .toList();

    final byCategory = <String, int>{};
    final byMerchant = <String, int>{};
    for (final e in inPeriod) {
      byCategory.update(e.categoryId, (v) => v + e.amountCents,
          ifAbsent: () => e.amountCents);
      final merchant = e.merchant?.trim();
      if (merchant != null && merchant.isNotEmpty) {
        byMerchant.update(merchant, (v) => v + e.amountCents,
            ifAbsent: () => e.amountCents);
      }
    }

    final slices = [
      for (final entry in byCategory.entries)
        if (categoriesById[entry.key] case final c?)
          (category: c, cents: entry.value),
    ]..sort((a, b) => b.cents.compareTo(a.cents));

    final topMerchants = byMerchant.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _PeriodToggle(
          period: period,
          onChanged: (p) => ref.read(analyticsPeriodProvider.notifier).set(p),
        ),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Spending by category'),
        const SizedBox(height: AppSpacing.md),
        AppCard(child: CategoryDonut(slices: slices)),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Last 6 months'),
        const SizedBox(height: AppSpacing.md),
        AppCard(child: MonthlyBarChart(bars: _last6Months(expenses))),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Top merchants'),
        const SizedBox(height: AppSpacing.sm),
        _TopMerchants(entries: topMerchants.take(5).toList()),
      ],
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({required this.period, required this.onChanged});

  final AnalyticsPeriod period;
  final ValueChanged<AnalyticsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AnalyticsPeriod>(
      segments: const [
        ButtonSegment(value: AnalyticsPeriod.day, label: Text('Day')),
        ButtonSegment(value: AnalyticsPeriod.week, label: Text('Week')),
        ButtonSegment(value: AnalyticsPeriod.month, label: Text('Month')),
      ],
      selected: {period},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
    );
  }
}

class _TopMerchants extends StatelessWidget {
  const _TopMerchants({required this.entries});

  final List<MapEntry<String, int>> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (entries.isEmpty) {
      return AppCard(
        child: Text(
          'Add a merchant to your expenses to see your top spots here.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
      );
    }
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              leading: CircleAvatar(
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.12),
                foregroundColor: theme.colorScheme.primary,
                child: Text('${i + 1}'),
              ),
              title: Text(entries[i].key),
              trailing: Text(
                formatCents(entries[i].value),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
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

List<MonthBar> _last6Months(List<Expense> all) {
  final now = DateTime.now();
  return [
    for (var i = 5; i >= 0; i--)
      () {
        final m = DateTime(now.year, now.month - i);
        final start = DateTime(m.year, m.month);
        final end = DateTime(m.year, m.month + 1);
        final cents = all
            .where((e) => !e.date.isBefore(start) && e.date.isBefore(end))
            .fold<int>(0, (s, e) => s + e.amountCents);
        return (label: DateFormat.MMM().format(m), cents: cents);
      }(),
  ];
}

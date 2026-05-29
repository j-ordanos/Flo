import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/shimmer_list.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../budgets/presentation/providers/budget_providers.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../../../expenses/presentation/widgets/add_expense_sheet.dart';
import '../../../expenses/presentation/widgets/expense_tile.dart';
import '../widgets/budget_health_row.dart';
import '../widgets/home_header.dart';
import '../widgets/spending_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      floatingActionButton: _GlowFab(onPressed: () => showAddExpenseSheet(context)),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(expensesProvider)
              ..invalidate(monthlyTotalProvider)
              ..invalidate(categoryTotalsProvider)
              ..invalidate(lastMonthTotalProvider);
          },
          child: expensesAsync.when(
            loading: () => const ShimmerList(),
            error: (_, _) => ErrorView(
              message: 'Could not load expenses.',
              onRetry: () => ref.invalidate(expensesProvider),
            ),
            data: (expenses) => _Body(expenses: expenses),
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.expenses});

  final List<Expense> expenses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spent = ref.watch(monthlyTotalProvider).value ?? 0;
    final income = ref.watch(monthlyIncomeProvider).value ?? 0;
    final budget = ref.watch(monthlyBudgetTotalProvider);
    final lastMonth = ref.watch(lastMonthTotalProvider).value ?? 0;

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        const HomeHeader(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: SpendingCard(
            spentCents: spent,
            budgetCents: budget,
            lastMonthCents: lastMonth,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (income > 0) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _IncomeBalanceRow(incomeCents: income, spentCents: spent),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (expenses.isEmpty)
          const _EmptyState()
        else ...[
          const BudgetHealthRow(),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Recent transactions'),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    children: [
                      for (var i = 0; i < expenses.take(6).length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        ExpenseTile(
                          expense: expenses[i],
                          onTap: () => context.push(
                              AppRoutes.transactionDetailPath(expenses[i].id)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Two compact cards: money in this month and the resulting balance.
class _IncomeBalanceRow extends StatelessWidget {
  const _IncomeBalanceRow({required this.incomeCents, required this.spentCents});

  final int incomeCents;
  final int spentCents;

  @override
  Widget build(BuildContext context) {
    final balance = incomeCents - spentCents;
    final positive = balance >= 0;
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            label: 'Income',
            value: '+${formatCents0(incomeCents)}',
            icon: Icons.south_west_rounded,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MiniStat(
            label: 'Balance',
            value: formatCents0(balance),
            icon: positive
                ? Icons.account_balance_wallet_outlined
                : Icons.trending_down_rounded,
            color: positive ? AppColors.success : AppColors.danger,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.hintColor)),
                const SizedBox(height: 2),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowFab extends StatelessWidget {
  const _GlowFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x6B4F46E5), // indigo @ ~42%
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        tooltip: 'Add expense',
        child: const Icon(Icons.add, size: 26),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 80),
      child: Column(
        children: [
          Container(
            width: 132,
            height: 132,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: dark ? AppColors.primarySoftDark : AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.account_balance_wallet_outlined,
                size: 56, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Your month, fresh', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add your first expense to see Flo come to life. '
            "We'll handle the categorising.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: AppSpacing.lg),
          Builder(
            builder: (context) => FilledButton.icon(
              onPressed: () => showAddExpenseSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Add your first expense'),
            ),
          ),
        ],
      ),
    );
  }
}

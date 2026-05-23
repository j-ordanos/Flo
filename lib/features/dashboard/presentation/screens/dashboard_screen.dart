import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../../../expenses/presentation/widgets/add_expense_sheet.dart';
import '../../../expenses/presentation/widgets/expense_tile.dart';
import '../widgets/category_spend_row.dart';
import '../widgets/monthly_summary_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Flo')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddExpenseSheet(context),
        tooltip: 'Add expense',
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(expensesProvider)
            ..invalidate(monthlyTotalProvider)
            ..invalidate(categoryTotalsProvider);
        },
        child: expensesAsync.when(
          loading: () => const LoadingView(),
          error: (_, _) => ErrorView(
            message: 'Could not load expenses.',
            onRetry: () => ref.invalidate(expensesProvider),
          ),
          data: (expenses) => _DashboardBody(expenses: expenses),
        ),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.expenses});

  final List<Expense> expenses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final spent = ref.watch(monthlyTotalProvider).value ?? 0;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        MonthlySummaryCard(spentCents: spent),
        const SizedBox(height: AppSpacing.lg),
        if (expenses.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxl),
            child: EmptyView(
              icon: Icons.receipt_long_outlined,
              title: 'No expenses yet',
              message: 'Tap + to add your first expense.',
              action: FilledButton.icon(
                onPressed: () => showAddExpenseSheet(context),
                icon: const Icon(Icons.add),
                label: const Text('Add expense'),
              ),
            ),
          )
        else ...[
          const CategorySpendRow(),
          const SizedBox(height: AppSpacing.lg),
          Text('Recent', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          for (final e in expenses.take(10))
            ExpenseTile(
              expense: e,
              onTap: () => context.push(AppRoutes.transactionDetailPath(e.id)),
            ),
        ],
      ],
    );
  }
}

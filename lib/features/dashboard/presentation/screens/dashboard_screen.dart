import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_gradients.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/shimmer_list.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../budgets/presentation/providers/budget_providers.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../../../expenses/presentation/widgets/add_expense_sheet.dart';
import '../../../expenses/presentation/widgets/expense_tile.dart';
import '../widgets/category_spend_row.dart';
import '../widgets/dashboard_hero_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddExpenseSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(expensesProvider)
              ..invalidate(monthlyTotalProvider)
              ..invalidate(categoryTotalsProvider);
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
    final budget = ref.watch(monthlyBudgetTotalProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        96,
      ),
      children: [
        const _GreetingHeader(),
        const SizedBox(height: AppSpacing.lg),
        DashboardHeroCard(spentCents: spent, budgetCents: budget),
        const SizedBox(height: AppSpacing.xl),
        if (expenses.isEmpty)
          const _EmptyState()
        else ...[
          const CategorySpendRow(),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Recent'),
          const SizedBox(height: AppSpacing.sm),
          _RecentList(expenses: expenses.take(10).toList()),
        ],
      ],
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader();

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.hintColor),
              ),
              Text('Your money', style: theme.textTheme.headlineSmall),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            gradient: AppGradients.brand,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.bolt, color: Colors.white),
        ),
      ],
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList({required this.expenses});

  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          for (var i = 0; i < expenses.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            ExpenseTile(
              expense: expenses[i],
              onTap: () => context
                  .push(AppRoutes.transactionDetailPath(expenses[i].id)),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: AppGradients.brand,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(Icons.savings_outlined,
                color: Colors.white, size: 40),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Start tracking', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Add your first expense to see your\nspending come to life.',
            textAlign: TextAlign.center,
            style:
                theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () => showAddExpenseSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Add expense'),
          ),
        ],
      ),
    );
  }
}

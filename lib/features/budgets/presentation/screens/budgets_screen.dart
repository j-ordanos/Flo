import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/shimmer_list.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../providers/budget_providers.dart';
import '../widgets/add_budget_sheet.dart';
import '../widgets/budget_card.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            tooltip: 'New budget',
            icon: const Icon(Icons.add),
            onPressed: () => showAddBudgetSheet(context),
          ),
        ],
      ),
      body: budgetsAsync.when(
        loading: () => const ShimmerList(),
        error: (_, _) => const ErrorView(message: 'Could not load budgets.'),
        data: (budgets) {
          if (budgets.isEmpty) {
            return EmptyView(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No budgets yet',
              message: 'Set a limit per category to stay on track.',
              action: FilledButton.icon(
                onPressed: () => showAddBudgetSheet(context),
                icon: const Icon(Icons.add),
                label: const Text('Create budget'),
              ),
            );
          }

          final categoriesById = ref.watch(categoriesByIdProvider);
          final totals = ref.watch(categoryTotalsProvider).value ?? const {};
          final totalLimit = ref.watch(monthlyBudgetTotalProvider);
          final totalSpent = ref.watch(monthlyTotalProvider).value ?? 0;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _Overview(spentCents: totalSpent, limitCents: totalLimit),
              const SizedBox(height: AppSpacing.xl),
              for (final b in budgets)
                if (categoriesById[b.categoryId] case final category?) ...[
                  BudgetCard(
                    category: category,
                    budget: b,
                    spentCents: totals[b.categoryId] ?? 0,
                    onTap: () => showAddBudgetSheet(context, initial: b),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.spentCents, required this.limitCents});

  final int spentCents;
  final int limitCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress =
        limitCents > 0 ? (spentCents / limitCents).clamp(0.0, 1.0) : 0.0;
    final remaining = limitCents - spentCents;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This month', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
              valueColor:
                  AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${formatCents(spentCents)} spent',
                style:
                    theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
              Text(
                remaining >= 0
                    ? '${formatCents(remaining)} left'
                    : '${formatCents(-remaining)} over',
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_gradients.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/money_formatter.dart';
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
    final theme = Theme.of(context);
    final budgetsAsync = ref.watch(budgetsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: budgetsAsync.when(
          loading: () => const ShimmerList(),
          error: (_, _) => const ErrorView(message: 'Could not load budgets.'),
          data: (budgets) {
            final categoriesById = ref.watch(categoriesByIdProvider);
            final totals = ref.watch(categoryTotalsProvider).value ?? const {};
            final totalLimit = ref.watch(monthlyBudgetTotalProvider);
            final totalSpent = ref.watch(monthlyTotalProvider).value ?? 0;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                        AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(DateFormat.yMMMM().format(DateTime.now()),
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: theme.hintColor)),
                              Text('Budgets',
                                  style: theme.textTheme.headlineSmall),
                            ],
                          ),
                        ),
                        _AddButton(onTap: () => showAddBudgetSheet(context)),
                      ],
                    ),
                  ),
                ),
                if (budgets.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyView(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'No budgets yet',
                      message: 'Set a limit per category to stay on track.',
                      action: FilledButton.icon(
                        onPressed: () => showAddBudgetSheet(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Create budget'),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, 0, AppSpacing.lg, 100),
                    sliver: SliverList.list(
                      children: [
                        _Overview(spentCents: totalSpent, limitCents: totalLimit),
                        const SizedBox(height: AppSpacing.lg),
                        Text('CATEGORIES',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.hintColor, letterSpacing: 0.4)),
                        const SizedBox(height: AppSpacing.sm),
                        for (final b in budgets)
                          if (categoriesById[b.categoryId] case final category?)
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: BudgetCard(
                                category: category,
                                budget: b,
                                spentCents: totals[b.categoryId] ?? 0,
                                onTap: () =>
                                    showAddBudgetSheet(context, initial: b),
                              ),
                            ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
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
    final pct = limitCents > 0 ? (spentCents / limitCents).clamp(0.0, 1.0) : 0.0;
    final remaining = limitCents - spentCents;
    final now = DateTime.now();
    final daysLeft = DateTime(now.year, now.month + 1, 0).day - now.day;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.circular(AppRadii.cardLg),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -56,
            right: -56,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MONTHLY TOTAL',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white70, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(formatCents(spentCents),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1)),
                  const SizedBox(width: 8),
                  Text('/ ${formatCents0(limitCents)}',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.22),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${(pct * 100).round()}% used',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  Text(
                    remaining >= 0
                        ? '${formatCents(remaining)} left · $daysLeft days'
                        : '${formatCents(-remaining)} over · $daysLeft days',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x524F46E5),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppColors.primary,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.add, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

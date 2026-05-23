import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../budgets/presentation/providers/budget_providers.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../categories/presentation/widgets/category_avatar.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';

/// Horizontal "Budget health" mini-cards. Falls back to top spending when no
/// budgets are set.
class BudgetHealthRow extends ConsumerWidget {
  const BudgetHealthRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(categoryTotalsProvider).value ?? const {};
    final categoriesById = ref.watch(categoriesByIdProvider);
    final budgets = ref.watch(budgetsByCategoryProvider);

    final cards = <Widget>[];
    if (budgets.isNotEmpty) {
      final entries = budgets.values
          .where((b) => categoriesById[b.categoryId] != null)
          .toList()
        ..sort((a, b) =>
            (totals[b.categoryId] ?? 0).compareTo(totals[a.categoryId] ?? 0));
      for (final b in entries.take(5)) {
        cards.add(_HealthCard(
          category: categoriesById[b.categoryId]!,
          spentCents: totals[b.categoryId] ?? 0,
          limitCents: b.limitCents,
        ));
      }
    } else {
      final spent = [
        for (final c in categoriesById.values)
          if ((totals[c.id] ?? 0) > 0) (c, totals[c.id]!),
      ]..sort((a, b) => b.$2.compareTo(a.$2));
      for (final (category, cents) in spent.take(5)) {
        cards.add(_HealthCard(category: category, spentCents: cents));
      }
    }

    if (cards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: SectionHeader(
            title: budgets.isNotEmpty ? 'Budget health' : 'Top spending',
            action: TextButton(
              onPressed: () => context.go(AppRoutes.budgets),
              child: const Text('See all'),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: cards.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, i) => cards[i],
          ),
        ),
      ],
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({
    required this.category,
    required this.spentCents,
    this.limitCents,
  });

  final Category category;
  final int spentCents;
  final int? limitCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLimit = limitCents != null && limitCents! > 0;
    final pct = hasLimit ? (spentCents / limitCents!).clamp(0.0, 1.0) : null;
    final barColor = switch (pct) {
      null => theme.colorScheme.primary,
      final p when p > 0.95 => AppColors.danger,
      final p when p > 0.8 => AppColors.warning,
      _ => theme.colorScheme.primary,
    };

    return SizedBox(
      width: 132,
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CategoryAvatar(
                    iconKey: category.icon,
                    colorHex: category.colorHex,
                    size: 30),
                if (pct != null)
                  Text('${(pct * 100).round()}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.hintColor, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 10),
            Text(category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(
              hasLimit
                  ? '${formatCents(spentCents)} / ${formatCents0(limitCents!)}'
                  : formatCents(spentCents),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
            ),
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: pct ?? 1,
                minHeight: 4,
                backgroundColor: theme.brightness == Brightness.dark
                    ? AppColors.trackDark
                    : AppColors.trackLight,
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

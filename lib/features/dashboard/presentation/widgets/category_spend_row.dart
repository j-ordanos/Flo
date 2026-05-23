import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../budgets/presentation/providers/budget_providers.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../categories/presentation/widgets/category_avatar.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';

/// Horizontal row of per-category spend for the current month, with budget
/// progress where a budget is set.
class CategorySpendRow extends ConsumerWidget {
  const CategorySpendRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(categoryTotalsProvider).value ?? const {};
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];
    final budgets = ref.watch(budgetsByCategoryProvider);

    final spent = [
      for (final c in categories)
        if ((totals[c.id] ?? 0) > 0) (c, totals[c.id]!),
    ]..sort((a, b) => b.$2.compareTo(a.$2));

    if (spent.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: spent.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, i) {
          final (category, cents) = spent[i];
          return _CategorySpendCard(
            category: category,
            cents: cents,
            limitCents: budgets[category.id]?.limitCents,
          );
        },
      ),
    );
  }
}

class _CategorySpendCard extends StatelessWidget {
  const _CategorySpendCard({
    required this.category,
    required this.cents,
    this.limitCents,
  });

  final Category category;
  final int cents;
  final int? limitCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLimit = limitCents != null && limitCents! > 0;
    final progress = hasLimit ? (cents / limitCents!).clamp(0.0, 1.0) : null;
    final color = switch (progress) {
      null => theme.colorScheme.primary,
      final p when p >= 1 => AppColors.danger,
      final p when p >= 0.8 => AppColors.warning,
      _ => AppColors.success,
    };

    return SizedBox(
      width: 152,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CategoryAvatar(
                iconKey: category.icon, colorHex: category.colorHex, size: 36),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
                const SizedBox(height: 2),
                Text(
                  formatCents(cents),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: LinearProgressIndicator(
                value: progress ?? 0,
                minHeight: 6,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(
                  hasLimit ? color : color.withValues(alpha: 0.35),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

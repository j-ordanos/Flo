import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../categories/presentation/widgets/category_avatar.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';

/// Horizontal row of per-category spend for the current month.
///
/// In P3 this gains budget % once budgets exist; for now it shows spend.
class CategorySpendRow extends ConsumerWidget {
  const CategorySpendRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(categoryTotalsProvider).value ?? const {};
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];

    final spent = [
      for (final c in categories)
        if ((totals[c.id] ?? 0) > 0) (c, totals[c.id]!),
    ]..sort((a, b) => b.$2.compareTo(a.$2));

    if (spent.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: spent.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final (category, cents) = spent[i];
          return _CategorySpendCard(category: category, cents: cents);
        },
      ),
    );
  }
}

class _CategorySpendCard extends StatelessWidget {
  const _CategorySpendCard({required this.category, required this.cents});

  final Category category;
  final int cents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CategoryAvatar(
                iconKey: category.icon, colorHex: category.colorHex, size: 34),
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            Text(
              formatCents(cents),
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

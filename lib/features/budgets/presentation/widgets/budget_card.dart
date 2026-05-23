import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/widgets/category_avatar.dart';
import '../../domain/entities/budget.dart';

/// A budget row: category, remaining/over status, spent-of-limit, and an
/// animated progress bar that warms amber → red as spending nears the limit.
class BudgetCard extends StatelessWidget {
  const BudgetCard({
    required this.category,
    required this.budget,
    required this.spentCents,
    this.onTap,
    super.key,
  });

  final Category category;
  final Budget budget;
  final int spentCents;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final limit = budget.limitCents;
    final ratio = limit > 0 ? spentCents / limit : 0.0;
    final progress = ratio.clamp(0.0, 1.0);
    final over = spentCents > limit;
    final remaining = limit - spentCents;
    final barColor = over
        ? AppColors.danger
        : ratio > 0.8
            ? AppColors.warning
            : theme.colorScheme.primary;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryAvatar(
                  iconKey: category.icon, colorHex: category.colorHex, size: 36),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      over
                          ? 'Over by ${formatCents(spentCents - limit)}'
                          : '${formatCents(remaining)} left',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: over ? AppColors.danger : theme.hintColor,
                        fontWeight: over ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatCents(spentCents),
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  Text('of ${formatCents0(limit)}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (_, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: theme.brightness == Brightness.dark
                    ? AppColors.trackDark
                    : AppColors.trackLight,
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

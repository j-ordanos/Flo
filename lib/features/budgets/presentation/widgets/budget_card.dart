import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/enums/budget_period.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/widgets/category_avatar.dart';
import '../../domain/entities/budget.dart';

/// Budget summary with an animated progress bar that warms amber → red as
/// spending approaches and exceeds the limit.
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
    final color = switch (ratio) {
      final r when r >= 1 => AppColors.danger,
      final r when r >= 0.8 => AppColors.warning,
      _ => AppColors.success,
    };

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryAvatar(iconKey: category.icon, colorHex: category.colorHex),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.name, style: theme.textTheme.titleMedium),
                    Text(
                      budget.period == BudgetPeriod.monthly
                          ? 'Monthly'
                          : 'Weekly',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ),
              ),
              if (over)
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.danger, size: 20),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (_, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${formatCents(spentCents)} of ${formatCents(limit)}',
                style:
                    theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
              Text(
                over
                    ? '${formatCents(spentCents - limit)} over'
                    : '${formatCents(remaining)} left',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: over ? AppColors.danger : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

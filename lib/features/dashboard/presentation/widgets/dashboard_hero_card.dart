import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_gradients.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/money_formatter.dart';

/// Gradient hero: month's total spend with a budget progress bar.
///
/// [budgetCents] of 0 means no budget is set yet.
class DashboardHeroCard extends StatelessWidget {
  const DashboardHeroCard({
    required this.spentCents,
    required this.budgetCents,
    super.key,
  });

  final int spentCents;
  final int budgetCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthName = DateFormat.MMMM().format(DateTime.now());
    final hasBudget = budgetCents > 0;
    final progress = hasBudget ? (spentCents / budgetCents).clamp(0.0, 1.0) : 0.0;
    final remaining = budgetCents - spentCents;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.glow(AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.white70, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '$monthName spending',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (hasBudget) _PercentPill(value: progress),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            formatCents(spentCents),
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (hasBudget) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                valueColor: AlwaysStoppedAnimation(
                  remaining < 0 ? AppColors.warning : Colors.white,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'of ${formatCents(budgetCents)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.white70),
                ),
                Text(
                  remaining >= 0
                      ? '${formatCents(remaining)} left'
                      : '${formatCents(-remaining)} over',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ] else
            Text(
              'Set a budget to track your progress',
              style:
                  theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
        ],
      ),
    );
  }
}

class _PercentPill extends StatelessWidget {
  const _PercentPill({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        '${(value * 100).round()}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

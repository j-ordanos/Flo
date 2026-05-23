import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/circular_stat_ring.dart';

/// Hero card: total spent this month inside a circular ring.
///
/// When [budgetCents] is set the ring shows spent/budget and tints by health;
/// otherwise it renders a full decorative ring (budgets land in P3).
class MonthlySummaryCard extends StatelessWidget {
  const MonthlySummaryCard({
    required this.spentCents,
    this.budgetCents,
    super.key,
  });

  final int spentCents;
  final int? budgetCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthName = DateFormat.MMMM().format(DateTime.now());
    final hasBudget = budgetCents != null && budgetCents! > 0;
    final progress = hasBudget ? spentCents / budgetCents! : null;
    final ringColor = switch (progress) {
      null => theme.colorScheme.primary,
      final p when p >= 1 => AppColors.danger,
      final p when p >= 0.8 => AppColors.warning,
      _ => AppColors.success,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            CircularStatRing(
              size: 116,
              progress: progress,
              progressColor: ringColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatCents(spentCents),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text('spent', style: theme.textTheme.labelSmall),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$monthName spending',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    hasBudget
                        ? 'of ${formatCents(budgetCents!)} budget'
                        : 'No budget set yet',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

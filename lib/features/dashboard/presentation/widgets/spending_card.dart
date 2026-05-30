import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_card.dart';

/// White spending card: a circular progress ring (spent vs budget) beside the
/// remaining amount and a month-over-month trend.
class SpendingCard extends StatelessWidget {
  const SpendingCard({
    required this.spentCents,
    required this.budgetCents,
    required this.lastMonthCents,
    super.key,
  });

  final int spentCents;
  final int budgetCents;
  final int lastMonthCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasBudget = budgetCents > 0;
    final pct = hasBudget ? (spentCents / budgetCents).clamp(0.0, 1.0) : 0.0;
    final ringColor = !hasBudget
        ? theme.colorScheme.primary
        : pct > 0.9
        ? AppColors.danger
        : pct > 0.75
        ? AppColors.warning
        : theme.colorScheme.primary;
    final remaining = budgetCents - spentCents;

    return AppCard(
      radius: AppRadii.cardLg,
      child: Row(
        children: [
          SizedBox(
            width: 132,
            height: 132,
            child: CustomPaint(
              painter: _RingPainter(
                progress: hasBudget ? pct : 0,
                color: ringColor,
                track: theme.brightness == Brightness.dark
                    ? AppColors.trackDark
                    : AppColors.trackLight,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SPENT',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.hintColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatCents0(spentCents),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      hasBudget ? 'of ${formatCents0(budgetCents)}' : 'spent',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat.yMMMM().format(DateTime.now()),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 4),
                if (hasBudget) ...[
                  Text(
                    formatCents0(math.max(0, remaining)),
                    style: theme.textTheme.headlineSmall,
                  ),
                  Text(
                    remaining >= 0 ? 'left to spend' : 'over budget',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ] else ...[
                  Text(
                    formatCents0(spentCents),
                    style: theme.textTheme.headlineSmall,
                  ),
                  Text(
                    'Set a budget to track',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _TrendChip(
                  spentCents: spentCents,
                  lastMonthCents: lastMonthCents,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChip extends StatelessWidget {
  const _TrendChip({required this.spentCents, required this.lastMonthCents});

  final int spentCents;
  final int lastMonthCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (lastMonthCents <= 0) {
      return Text(
        'No prior month yet',
        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
      );
    }
    final delta = (spentCents - lastMonthCents) / lastMonthCents;
    final under = delta <= 0;
    final color = under ? AppColors.success : AppColors.danger;
    final pct = (delta.abs() * 100).round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          under ? Icons.trending_down : Icons.trending_up,
          size: 15,
          color: color,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '$pct% ${under ? 'under' : 'over'} last month',
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - 12) / 2;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, base..color = track);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        progress * 2 * math.pi,
        false,
        base..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}

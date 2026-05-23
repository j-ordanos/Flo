import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A circular progress ring with a centered [child].
///
/// [progress] is 0..1; pass `null` for a full decorative ring (used until
/// budgets exist to drive a real percentage).
class CircularStatRing extends StatelessWidget {
  const CircularStatRing({
    required this.size,
    required this.child,
    this.progress,
    this.trackColor,
    this.progressColor,
    this.strokeWidth = 12,
    super.key,
  });

  final double size;
  final Widget child;
  final double? progress;
  final Color? trackColor;
  final Color? progressColor;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress,
          trackColor:
              trackColor ?? theme.colorScheme.surfaceContainerHighest,
          progressColor: progressColor ?? theme.colorScheme.primary,
          strokeWidth: strokeWidth,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  final double? progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, base..color = trackColor);

    final sweep = (progress == null ? 1.0 : progress!.clamp(0.0, 1.0)) *
        2 *
        math.pi;
    if (sweep > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweep,
        false,
        base..color = progressColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.progressColor != progressColor ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}

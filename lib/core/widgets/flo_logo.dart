import 'package:flutter/material.dart';

import '../constants/app_gradients.dart';

/// The Flo logomark: a gradient rounded-square with a stylized white "F" and a
/// flowing wave beneath it. Recreated from the design's SVG (80×80 viewBox).
class FloLogo extends StatelessWidget {
  const FloLogo({this.size = 80, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.circular(size * 0.275),
      ),
      child: CustomPaint(painter: _FloGlyphPainter(size)),
    );
  }
}

class _FloGlyphPainter extends CustomPainter {
  _FloGlyphPainter(this.box);

  final double box;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 80;

    // Stylized "F" polygon.
    final f = Path()
      ..moveTo(28 * s, 22 * s)
      ..lineTo(56 * s, 22 * s)
      ..lineTo(56 * s, 30 * s)
      ..lineTo(36 * s, 30 * s)
      ..lineTo(36 * s, 38 * s)
      ..lineTo(52 * s, 38 * s)
      ..lineTo(52 * s, 46 * s)
      ..lineTo(36 * s, 46 * s)
      ..lineTo(36 * s, 60 * s)
      ..lineTo(28 * s, 60 * s)
      ..close();
    canvas.drawPath(
      f,
      Paint()..color = Colors.white.withValues(alpha: 0.96),
    );

    // Flowing wave underneath.
    final wave = Path()..moveTo(18 * s, 56 * s);
    var up = false;
    for (var x = 18.0; x < 58; x += 10) {
      wave.relativeCubicTo(
          4 * s, 0, 6 * s, (up ? 3 : -3) * s, 10 * s, (up ? 3 : -3) * s);
      up = !up;
    }
    canvas.drawPath(
      wave,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * s
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant _FloGlyphPainter oldDelegate) =>
      oldDelegate.box != box;
}

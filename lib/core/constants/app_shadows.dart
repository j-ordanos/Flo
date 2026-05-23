import 'package:flutter/material.dart';

/// Soft, layered shadows for elevated surfaces. Tuned per brightness so cards
/// read as gently lifted rather than heavy.
abstract final class AppShadows {
  const AppShadows._();

  static List<BoxShadow> card(Brightness brightness) =>
      brightness == Brightness.dark
          ? const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ]
          : const [
              BoxShadow(
                color: Color(0x14101828),
                blurRadius: 24,
                offset: Offset(0, 12),
                spreadRadius: -6,
              ),
              BoxShadow(
                color: Color(0x0D101828),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ];

  /// Colored glow used under the brand gradient hero card.
  static List<BoxShadow> glow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.35),
          blurRadius: 28,
          offset: const Offset(0, 14),
          spreadRadius: -8,
        ),
      ];
}

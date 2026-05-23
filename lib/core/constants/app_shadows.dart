import 'package:flutter/material.dart';

/// Soft, layered shadows for elevated surfaces. Tuned per brightness so cards
/// read as gently lifted rather than heavy.
abstract final class AppShadows {
  const AppShadows._();

  static List<BoxShadow> card(Brightness brightness) =>
      brightness == Brightness.dark
          ? const []
          : const [
              BoxShadow(
                color: Color(0x0A0F172A), // rgba(15,23,42,0.04)
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
              BoxShadow(
                color: Color(0x0A0F172A),
                blurRadius: 2,
                offset: Offset(0, 1),
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

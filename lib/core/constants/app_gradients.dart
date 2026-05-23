import 'package:flutter/material.dart';

/// Brand gradients used for hero surfaces.
abstract final class AppGradients {
  const AppGradients._();

  /// Indigo → violet diagonal used on the dashboard hero card.
  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF4F46E5), Color(0xFF7C3AED)],
  );
}

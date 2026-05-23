import 'package:flutter/material.dart';

/// Flo brand palette and semantic colors.
///
/// Source of truth for the design system described in `design.txt` / `PLAN.md`.
abstract final class AppColors {
  const AppColors._();

  // Brand / semantic
  static const Color primary = Color(0xFF4F46E5); // deep indigo
  static const Color success = Color(0xFF10B981); // emerald
  static const Color warning = Color(0xFFF59E0B); // amber
  static const Color danger = Color(0xFFEF4444); // rose

  // Light surfaces
  static const Color lightBackground = Color(0xFFF9FAFB);
  static const Color lightSurface = Color(0xFFFFFFFF);

  // Dark surfaces
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);

  // Text
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Borders / dividers
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF334155);
}

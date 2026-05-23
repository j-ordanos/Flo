import 'package:flutter/material.dart';

/// Flo brand palette and semantic colors — mirrors the Flo design tokens.
abstract final class AppColors {
  const AppColors._();

  // Brand / semantic
  static const Color primary = Color(0xFF4F46E5); // deep indigo
  static const Color primaryDeep = Color(0xFF4338CA);
  static const Color primarySoft = Color(0xFFEEF2FF); // light indigo wash
  static const Color primarySoftDark = Color(0xFF1E1B4B);
  static const Color violet = Color(0xFF7C3AED); // gradient end
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // Light surfaces
  static const Color lightBackground = Color(0xFFF9FAFB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF3F4F6);

  // Dark surfaces
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceAlt = Color(0x1494A3B8); // slate @ ~8%

  // Text
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textMutedLight = Color(0xFF475569);
  static const Color textDimLight = Color(0xFF94A3B8);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textMutedDark = Color(0xFF94A3B8);
  static const Color textDimDark = Color(0xFF64748B);

  // Borders / dividers
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0x2994A3B8); // slate @ ~16%
  static const Color dividerLight = Color(0xFFF1F5F9);
  static const Color dividerDark = Color(0x1F94A3B8); // slate @ ~12%

  // Track (progress backgrounds)
  static const Color trackLight = Color(0xFFE2E8F0);
  static const Color trackDark = Color(0x2E94A3B8);
}

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import 'app_typography.dart';

/// Light and dark [ThemeData] derived from the Flo design tokens.
abstract final class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final textTheme = _tunedText(AppTypography.textTheme(brightness));

    final onSurface =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final muted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final inputFill =
        isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: AppColors.primary,
      error: AppColors.danger,
      surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      onSurface: onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme.apply(
        bodyColor: onSurface,
        displayColor: onSurface,
      ),
      scaffoldBackgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      hintColor: muted,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle:
            textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
          textStyle:
              textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
          textStyle:
              textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle:
              textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: _inputBorder(Colors.transparent),
        enabledBorder: _inputBorder(Colors.transparent),
        focusedBorder: _inputBorder(AppColors.primary, width: 1.5),
        hintStyle: textTheme.bodyMedium?.copyWith(color: muted),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withValues(alpha: 0.14),
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        space: 1,
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.button),
        borderSide: BorderSide(color: color, width: width),
      );

  static TextTheme _tunedText(TextTheme base) => base.copyWith(
        displaySmall: base.displaySmall
            ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1),
        headlineMedium: base.headlineMedium
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.8),
        headlineSmall: base.headlineSmall
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        titleLarge: base.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
        titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      );
}

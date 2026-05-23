import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Inter type scale built on top of the Material 2021 baseline.
abstract final class AppTypography {
  const AppTypography._();

  static TextTheme textTheme(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? Typography.material2021().white
        : Typography.material2021().black;
    return GoogleFonts.interTextTheme(base);
  }
}

/// 8px base spacing grid.
abstract final class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Corner radii. Cards use a softer 20 for a more modern feel; buttons 14;
/// pills 99.
abstract final class AppRadii {
  const AppRadii._();

  static const double card = 20;
  static const double button = 14;
  static const double pill = 99;
}

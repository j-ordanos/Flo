import 'package:flutter/painting.dart';

/// Parses an `RRGGBB` or `AARRGGBB` hex string (optionally `#`-prefixed).
Color hexToColor(String hex) {
  var value = hex.replaceFirst('#', '').toUpperCase();
  if (value.length == 6) value = 'FF$value';
  return Color(int.parse(value, radix: 16));
}

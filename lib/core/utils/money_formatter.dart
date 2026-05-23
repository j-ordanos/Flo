import 'package:intl/intl.dart';

/// Formats integer [cents] as a currency string.
///
/// Currency becomes user-selectable in P3; for now it defaults to a `$` symbol
/// with two decimal places.
String formatCents(int cents, {String symbol = '\$'}) {
  return NumberFormat.currency(symbol: symbol, decimalDigits: 2)
      .format(cents / 100);
}

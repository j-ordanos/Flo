import 'package:intl/intl.dart';

/// App-wide currency symbol, updated by the currency setting (Profile).
/// Kept as a simple static so `formatCents` can be called without a `Ref`;
/// the root app rebuilds when the currency changes so values refresh.
class Money {
  Money._();

  static String symbol = '\$';
}

/// Formats integer [cents] as a currency string using the active symbol.
String formatCents(int cents, {String? symbol}) =>
    NumberFormat.currency(symbol: symbol ?? Money.symbol, decimalDigits: 2)
        .format(cents / 100);

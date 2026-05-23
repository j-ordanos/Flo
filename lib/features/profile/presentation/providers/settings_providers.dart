import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/money/currency.dart';
import '../../../../core/providers/preferences_provider.dart';
import '../../../../core/utils/money_formatter.dart';

/// Selected display currency, persisted to SharedPreferences.
class CurrencyNotifier extends Notifier<Currency> {
  static const _key = 'currency_code';

  @override
  Currency build() {
    final code = ref.watch(sharedPreferencesProvider).getString(_key);
    final currency = kCurrencies.firstWhere(
      (c) => c.code == code,
      orElse: () => kCurrencies.first,
    );
    Money.symbol = currency.symbol;
    return currency;
  }

  Future<void> select(Currency currency) async {
    Money.symbol = currency.symbol;
    state = currency;
    await ref.read(sharedPreferencesProvider).setString(_key, currency.code);
  }
}

final currencyProvider =
    NotifierProvider<CurrencyNotifier, Currency>(CurrencyNotifier.new);

/// Selected theme mode, persisted to SharedPreferences.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final name = ref.watch(sharedPreferencesProvider).getString(_key);
    return ThemeMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(_key, mode.name);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

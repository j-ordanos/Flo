/// A selectable display currency.
class Currency {
  const Currency({required this.code, required this.symbol, required this.name});

  final String code;
  final String symbol;
  final String name;
}

/// Supported display currencies.
const List<Currency> kCurrencies = [
  Currency(code: 'USD', symbol: r'$', name: 'US Dollar'),
  Currency(code: 'EUR', symbol: '€', name: 'Euro'),
  Currency(code: 'GBP', symbol: '£', name: 'British Pound'),
  Currency(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
  Currency(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
  Currency(code: 'CAD', symbol: r'CA$', name: 'Canadian Dollar'),
  Currency(code: 'AUD', symbol: r'A$', name: 'Australian Dollar'),
  Currency(code: 'NGN', symbol: '₦', name: 'Nigerian Naira'),
  Currency(code: 'ETB', symbol: 'Br', name: 'Ethiopian Birr'),
];

import 'package:flutter/material.dart';

/// Maps a category's stored icon key to a Material icon.
const Map<String, IconData> kCategoryIcons = {
  // Defaults
  'food': Icons.restaurant_outlined,
  'transport': Icons.directions_car_outlined,
  'shopping': Icons.shopping_bag_outlined,
  'health': Icons.favorite_border,
  'entertainment': Icons.movie_outlined,
  'bills': Icons.receipt_long_outlined,
  'other': Icons.circle_outlined,
  // Food & drink
  'coffee': Icons.local_cafe_outlined,
  'groceries': Icons.local_grocery_store_outlined,
  'restaurant': Icons.dinner_dining_outlined,
  // Transport & travel
  'transit': Icons.directions_bus_outlined,
  'fuel': Icons.local_gas_station_outlined,
  'flight': Icons.flight_outlined,
  'travel': Icons.luggage_outlined,
  // Shopping & lifestyle
  'clothing': Icons.checkroom_outlined,
  'gifts': Icons.card_giftcard_outlined,
  'beauty': Icons.spa_outlined,
  // Health
  'medical': Icons.medical_services_outlined,
  'fitness': Icons.fitness_center_outlined,
  'pets': Icons.pets_outlined,
  // Entertainment
  'music': Icons.music_note_outlined,
  'games': Icons.sports_esports_outlined,
  'books': Icons.menu_book_outlined,
  // Bills & home
  'utilities': Icons.bolt_outlined,
  'phone': Icons.smartphone_outlined,
  'internet': Icons.wifi_outlined,
  'subscriptions': Icons.subscriptions_outlined,
  'home': Icons.home_outlined,
  'rent': Icons.house_outlined,
  // Other
  'education': Icons.school_outlined,
  'kids': Icons.child_care_outlined,
  'savings': Icons.savings_outlined,
  'salary': Icons.payments_outlined,
  'charity': Icons.volunteer_activism_outlined,
  // Income
  'paycheck': Icons.account_balance_wallet_outlined,
  'freelance': Icons.work_outline,
  'business': Icons.storefront_outlined,
  'investment': Icons.trending_up_outlined,
  'dividends': Icons.pie_chart_outline,
  'interest': Icons.account_balance_outlined,
  'refund': Icons.replay_outlined,
  'bonus': Icons.emoji_events_outlined,
  'rental': Icons.apartment_outlined,
  'sales': Icons.sell_outlined,
  'tips': Icons.attach_money_outlined,
  'gift_income': Icons.redeem_outlined,
};

IconData iconForCategoryKey(String key) =>
    kCategoryIcons[key] ?? Icons.circle_outlined;

/// Icon keys offered in the icon picker, in display order.
const List<String> kSelectableIconKeys = [
  'food', 'coffee', 'groceries', 'restaurant',
  'transport', 'transit', 'fuel', 'flight', 'travel',
  'shopping', 'clothing', 'gifts', 'beauty',
  'health', 'medical', 'fitness', 'pets',
  'entertainment', 'music', 'games', 'books',
  'bills', 'utilities', 'phone', 'internet', 'subscriptions',
  'home', 'rent', 'education', 'kids',
  'savings', 'salary', 'charity', 'other',
];

/// Income-related icon keys, surfaced first when creating an income category.
const List<String> kIncomeIconKeys = [
  'paycheck', 'salary', 'freelance', 'business',
  'investment', 'dividends', 'interest', 'rental',
  'sales', 'tips', 'bonus', 'refund',
  'gift_income', 'savings', 'other',
];

/// Color choices (RRGGBB) for custom categories.
const List<String> kCategoryPalette = [
  'F59E0B', '3B82F6', 'EC4899', '10B981', '8B5CF6', 'EF4444', '64748B',
  '06B6D4', 'F97316', '14B8A6', 'A855F7', 'E11D48', '22C55E', '0EA5E9',
];

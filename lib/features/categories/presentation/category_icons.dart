import 'package:flutter/material.dart';

/// Maps a category's stored icon key to a Material icon.
const Map<String, IconData> kCategoryIcons = {
  'food': Icons.restaurant_outlined,
  'transport': Icons.directions_car_outlined,
  'shopping': Icons.shopping_bag_outlined,
  'health': Icons.favorite_outline,
  'entertainment': Icons.movie_outlined,
  'bills': Icons.receipt_long_outlined,
  'other': Icons.category_outlined,
};

IconData iconForCategoryKey(String key) =>
    kCategoryIcons[key] ?? Icons.category_outlined;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';

/// Single app-wide Drift database instance.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

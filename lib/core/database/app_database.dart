import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../enums/budget_period.dart';
import '../enums/sync_operation.dart';
import '../enums/sync_status.dart';
import 'daos/category_dao.dart';
import 'daos/expense_dao.dart';
import 'tables/budgets.dart';
import 'tables/categories.dart';
import 'tables/expenses.dart';
import 'tables/sync_queue.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Expenses, Categories, Budgets, SyncQueue],
  daos: [ExpenseDao, CategoryDao],
)
class AppDatabase extends _$AppDatabase {
  /// Pass a custom [executor] (e.g. an in-memory database) in tests.
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;
}

QueryExecutor _openConnection() => driftDatabase(name: 'flo');

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../constants/app_constants.dart';
import '../enums/budget_period.dart';
import '../enums/sync_operation.dart';
import '../enums/sync_status.dart';
import 'daos/budget_dao.dart';
import 'daos/category_dao.dart';
import 'daos/expense_dao.dart';
import 'tables/budgets.dart';
import 'tables/categories.dart';
import 'tables/expenses.dart';
import 'tables/sync_queue.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Expenses, Categories, Budgets, SyncQueue],
  daos: [ExpenseDao, CategoryDao, BudgetDao],
)
class AppDatabase extends _$AppDatabase {
  /// Pass a custom [executor] (e.g. an in-memory database) in tests.
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(expenses, expenses.receiptPath);
          }
        },
      );

  /// Re-assigns all locally-created (`kLocalUserId`) rows to [newUserId] on first
  /// sign-in, marking them pending so they upload during sync (P6).
  Future<void> reassignLocalUserData(String newUserId) async {
    await transaction(() async {
      await (update(categories)..where((t) => t.userId.equals(kLocalUserId)))
          .write(CategoriesCompanion(
        userId: Value(newUserId),
        syncStatus: const Value(SyncStatus.pending),
      ));
      await (update(expenses)..where((t) => t.userId.equals(kLocalUserId)))
          .write(ExpensesCompanion(
        userId: Value(newUserId),
        syncStatus: const Value(SyncStatus.pending),
      ));
      await (update(budgets)..where((t) => t.userId.equals(kLocalUserId)))
          .write(BudgetsCompanion(
        userId: Value(newUserId),
        syncStatus: const Value(SyncStatus.pending),
      ));
    });
  }
}

QueryExecutor _openConnection() => driftDatabase(name: 'flo');

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../constants/app_constants.dart';
import '../enums/budget_period.dart';
import '../enums/sync_operation.dart';
import '../enums/sync_status.dart';
import '../enums/transaction_type.dart';
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
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(expenses, expenses.receiptPath);
          }
          if (from < 3) {
            await m.addColumn(expenses, expenses.type);
          }
        },
      );

  /// Collapses duplicate default categories that accumulated from re-seeding
  /// across installs/logins (each used to get a random id). Groups live default
  /// rows by icon, keeps one survivor (preferring the deterministic id), repoints
  /// any expenses/budgets to it, and soft-deletes the rest (marked pending so the
  /// deletes propagate during sync). Returns true if anything was merged.
  Future<bool> dedupeDefaultCategories(String userId) {
    return transaction(() async {
      final defaults = await (select(categories)
            ..where((c) =>
                c.userId.equals(userId) &
                c.isDefault.equals(true) &
                c.deletedAt.isNull())
            ..orderBy([(c) => OrderingTerm.asc(c.createdAt)]))
          .get();

      final byIcon = <String, List<CategoryRow>>{};
      for (final c in defaults) {
        byIcon.putIfAbsent(c.icon, () => <CategoryRow>[]).add(c);
      }

      final now = DateTime.now().toUtc();
      var changed = false;
      for (final entry in byIcon.entries) {
        final group = entry.value;
        if (group.length <= 1) continue;
        final canonicalId = defaultCategoryId(userId, entry.key);
        final survivor = group.firstWhere(
          (c) => c.id == canonicalId,
          orElse: () => group.first,
        );
        for (final loser in group) {
          if (loser.id == survivor.id) continue;
          changed = true;
          await (update(expenses)..where((e) => e.categoryId.equals(loser.id)))
              .write(ExpensesCompanion(
            categoryId: Value(survivor.id),
            updatedAt: Value(now),
            syncStatus: const Value(SyncStatus.pending),
          ));
          await (update(budgets)..where((b) => b.categoryId.equals(loser.id)))
              .write(BudgetsCompanion(
            categoryId: Value(survivor.id),
            updatedAt: Value(now),
            syncStatus: const Value(SyncStatus.pending),
          ));
          await (update(categories)..where((c) => c.id.equals(loser.id)))
              .write(CategoriesCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
            syncStatus: const Value(SyncStatus.pending),
          ));
        }
      }
      return changed;
    });
  }

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

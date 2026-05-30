import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../enums/budget_period.dart';
import '../enums/category_kind.dart';
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
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(expenses, expenses.receiptPath);
          }
          if (from < 3) {
            await m.addColumn(expenses, expenses.type);
          }
          if (from < 4) {
            await m.addColumn(categories, categories.kind);
          }
        },
      );

  /// Fixes legacy categories whose id isn't a valid UUID (the old
  /// `cat_<user>_<kind>_<icon>` scheme), which Supabase rejected on sync because
  /// `categories.id` is type `uuid`. For each bad row: create the canonical row
  /// under a valid UUID (deterministic for defaults, random for custom),
  /// repoint expenses/budgets, then hard-delete the bad row (it never synced, so
  /// nothing to propagate). Returns true if anything was migrated.
  Future<bool> migrateNonUuidCategoryIds(String userId) {
    return transaction(() async {
      final all = await (select(categories)
            ..where((c) => c.userId.equals(userId)))
          .get();
      final now = DateTime.now().toUtc();
      var changed = false;
      for (final c in all) {
        if (isValidUuid(c.id)) continue;
        changed = true;
        final newId = c.isDefault
            ? defaultCategoryId(userId, c.kind.name, c.icon)
            : const Uuid().v4();

        final existing = await (select(categories)
              ..where((t) => t.id.equals(newId)))
            .getSingleOrNull();
        if (existing == null) {
          await into(categories).insert(
            c.copyWith(id: newId, updatedAt: now, syncStatus: SyncStatus.pending),
          );
        }
        await (update(expenses)..where((e) => e.categoryId.equals(c.id)))
            .write(ExpensesCompanion(
          categoryId: Value(newId),
          updatedAt: Value(now),
          syncStatus: const Value(SyncStatus.pending),
        ));
        await (update(budgets)..where((b) => b.categoryId.equals(c.id)))
            .write(BudgetsCompanion(
          categoryId: Value(newId),
          updatedAt: Value(now),
          syncStatus: const Value(SyncStatus.pending),
        ));
        await (delete(categories)..where((t) => t.id.equals(c.id))).go();
      }
      return changed;
    });
  }

  /// Collapses duplicate default categories that accumulated from re-seeding
  /// across installs/logins (each used to get a random id). Groups live default
  /// rows by (kind, icon), keeps one survivor (preferring the deterministic id),
  /// repoints any expenses/budgets to it, and soft-deletes the rest (marked
  /// pending so the deletes propagate during sync). Returns true if merged.
  Future<bool> dedupeDefaultCategories(String userId) {
    return transaction(() async {
      final defaults = await (select(categories)
            ..where((c) =>
                c.userId.equals(userId) &
                c.isDefault.equals(true) &
                c.deletedAt.isNull())
            ..orderBy([(c) => OrderingTerm.asc(c.createdAt)]))
          .get();

      final byKey = <String, List<CategoryRow>>{};
      for (final c in defaults) {
        byKey.putIfAbsent('${c.kind.name}_${c.icon}', () => <CategoryRow>[])
            .add(c);
      }

      final now = DateTime.now().toUtc();
      var changed = false;
      for (final group in byKey.values) {
        if (group.length <= 1) continue;
        final first = group.first;
        final canonicalId =
            defaultCategoryId(userId, first.kind.name, first.icon);
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

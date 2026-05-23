import 'package:drift/drift.dart';

import '../../enums/sync_status.dart';
import '../app_database.dart';
import '../tables/budgets.dart';

part 'budget_dao.g.dart';

/// Data access for [Budgets]. Reads exclude soft-deleted rows.
@DriftAccessor(tables: [Budgets])
class BudgetDao extends DatabaseAccessor<AppDatabase> with _$BudgetDaoMixin {
  BudgetDao(super.db);

  Stream<List<BudgetRow>> watchBudgets(String userId) => (select(budgets)
        ..where((b) => b.userId.equals(userId) & b.deletedAt.isNull()))
      .watch();

  Future<BudgetRow?> findByCategory(String userId, String categoryId) =>
      (select(budgets)
            ..where((b) =>
                b.userId.equals(userId) &
                b.categoryId.equals(categoryId) &
                b.deletedAt.isNull()))
          .getSingleOrNull();

  Future<void> upsert(BudgetRow row) =>
      into(budgets).insertOnConflictUpdate(row);

  Future<void> softDelete(String id, DateTime when) =>
      (update(budgets)..where((b) => b.id.equals(id))).write(
        BudgetsCompanion(
          deletedAt: Value(when),
          updatedAt: Value(when),
          syncStatus: const Value(SyncStatus.pending),
        ),
      );
}

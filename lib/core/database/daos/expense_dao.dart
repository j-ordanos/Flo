import 'package:drift/drift.dart';

import '../../enums/sync_status.dart';
import '../app_database.dart';
import '../tables/expenses.dart';

part 'expense_dao.g.dart';

/// Data access for [Expenses]. All reads exclude soft-deleted rows.
@DriftAccessor(tables: [Expenses])
class ExpenseDao extends DatabaseAccessor<AppDatabase> with _$ExpenseDaoMixin {
  ExpenseDao(super.db);

  Stream<List<ExpenseRow>> watchExpenses(
    String userId, {
    DateTime? from,
    DateTime? to,
  }) {
    final query = select(expenses)
      ..where((e) => e.userId.equals(userId) & e.deletedAt.isNull());
    if (from != null) {
      query.where((e) => e.date.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      query.where((e) => e.date.isSmallerThanValue(to));
    }
    query.orderBy([
      (e) => OrderingTerm.desc(e.date),
      (e) => OrderingTerm.desc(e.createdAt),
    ]);
    return query.watch();
  }

  Stream<ExpenseRow?> watchById(String id) =>
      (select(expenses)..where((e) => e.id.equals(id))).watchSingleOrNull();

  Future<ExpenseRow?> findById(String id) =>
      (select(expenses)..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<void> upsert(ExpenseRow row) =>
      into(expenses).insertOnConflictUpdate(row);

  Future<void> softDelete(String id, DateTime when) =>
      (update(expenses)..where((e) => e.id.equals(id))).write(
        ExpensesCompanion(
          deletedAt: Value(when),
          updatedAt: Value(when),
          syncStatus: const Value(SyncStatus.pending),
        ),
      );

  /// Total cents spent in [month] (its calendar month), excluding deletes.
  Stream<int> watchMonthlyTotal(String userId, DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final total = expenses.amountCents.sum();
    final query = selectOnly(expenses)
      ..addColumns([total])
      ..where(
        expenses.userId.equals(userId) &
            expenses.deletedAt.isNull() &
            expenses.date.isBiggerOrEqualValue(start) &
            expenses.date.isSmallerThanValue(end),
      );
    return query.watchSingle().map((row) => row.read(total) ?? 0);
  }

  /// Map of `categoryId -> total cents` for [month], excluding deletes.
  Stream<Map<String, int>> watchTotalsByCategory(
    String userId,
    DateTime month,
  ) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final total = expenses.amountCents.sum();
    final query = selectOnly(expenses)
      ..addColumns([expenses.categoryId, total])
      ..where(
        expenses.userId.equals(userId) &
            expenses.deletedAt.isNull() &
            expenses.date.isBiggerOrEqualValue(start) &
            expenses.date.isSmallerThanValue(end),
      )
      ..groupBy([expenses.categoryId]);
    return query.watch().map(
          (rows) => {
            for (final r in rows)
              r.read(expenses.categoryId)!: r.read(total) ?? 0,
          },
        );
  }
}

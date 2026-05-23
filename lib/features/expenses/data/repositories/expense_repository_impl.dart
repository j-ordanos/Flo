import '../../../../core/database/daos/expense_dao.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../mappers/expense_mapper.dart';

/// Local-first [ExpenseRepository]. Writes go straight to Drift; reads are
/// reactive streams mapped to domain entities. Sync enqueueing arrives in P6.
class ExpenseRepositoryImpl implements ExpenseRepository {
  ExpenseRepositoryImpl(this._dao);

  final ExpenseDao _dao;

  @override
  Future<void> addExpense(Expense expense) => _dao.upsert(expense.toRow());

  @override
  Future<void> updateExpense(Expense expense) => _dao.upsert(expense.toRow());

  @override
  Future<void> deleteExpense(String id) =>
      _dao.softDelete(id, DateTime.now().toUtc());

  @override
  Stream<List<Expense>> watchExpenses(
    String userId, {
    DateTime? from,
    DateTime? to,
  }) =>
      _dao
          .watchExpenses(userId, from: from, to: to)
          .map((rows) => rows.map((r) => r.toEntity()).toList());

  @override
  Stream<Expense?> watchExpense(String id) =>
      _dao.watchById(id).map((row) => row?.toEntity());

  @override
  Stream<int> watchMonthlyTotal(String userId, DateTime month) =>
      _dao.watchMonthlyTotal(userId, month);

  @override
  Stream<Map<String, int>> watchTotalsByCategory(
    String userId,
    DateTime month,
  ) =>
      _dao.watchTotalsByCategory(userId, month);
}

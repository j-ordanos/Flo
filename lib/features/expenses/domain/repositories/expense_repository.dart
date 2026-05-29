import '../entities/expense.dart';

/// Local-first expense access. Writes hit Drift immediately; the sync outbox is
/// wired in P6.
abstract interface class ExpenseRepository {
  Future<void> addExpense(Expense expense);
  Future<void> updateExpense(Expense expense);

  /// Soft delete (sets `deletedAt`).
  Future<void> deleteExpense(String id);

  Stream<List<Expense>> watchExpenses(
    String userId, {
    DateTime? from,
    DateTime? to,
  });
  Stream<Expense?> watchExpense(String id);
  Stream<int> watchMonthlyTotal(String userId, DateTime month);
  Stream<int> watchMonthlyIncome(String userId, DateTime month);
  Stream<Map<String, int>> watchTotalsByCategory(String userId, DateTime month);
}

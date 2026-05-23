import '../entities/budget.dart';

/// Local-first budget access.
abstract interface class BudgetRepository {
  Stream<List<Budget>> watchBudgets(String userId);
  Future<Budget?> findByCategory(String userId, String categoryId);
  Future<void> upsertBudget(Budget budget);

  /// Soft delete (sets `deletedAt`).
  Future<void> deleteBudget(String id);
}

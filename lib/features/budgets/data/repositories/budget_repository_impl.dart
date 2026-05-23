import '../../../../core/database/daos/budget_dao.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../mappers/budget_mapper.dart';

/// Local-first [BudgetRepository] over Drift.
class BudgetRepositoryImpl implements BudgetRepository {
  BudgetRepositoryImpl(this._dao);

  final BudgetDao _dao;

  @override
  Stream<List<Budget>> watchBudgets(String userId) => _dao
      .watchBudgets(userId)
      .map((rows) => rows.map((r) => r.toEntity()).toList());

  @override
  Future<Budget?> findByCategory(String userId, String categoryId) async =>
      (await _dao.findByCategory(userId, categoryId))?.toEntity();

  @override
  Future<void> upsertBudget(Budget budget) => _dao.upsert(budget.toRow());

  @override
  Future<void> deleteBudget(String id) =>
      _dao.softDelete(id, DateTime.now().toUtc());
}

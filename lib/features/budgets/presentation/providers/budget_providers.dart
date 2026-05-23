import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/budget_period.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/session_provider.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return BudgetRepositoryImpl(db.budgetDao);
});

final budgetsProvider = StreamProvider<List<Budget>>((ref) {
  final repo = ref.watch(budgetRepositoryProvider);
  return repo.watchBudgets(ref.watch(currentUserIdProvider));
});

/// Lookup of `categoryId -> Budget`.
final budgetsByCategoryProvider = Provider<Map<String, Budget>>((ref) {
  final budgets = ref.watch(budgetsProvider).value ?? const [];
  return {for (final b in budgets) b.categoryId: b};
});

/// Total monthly-equivalent budget (weekly limits counted as ~4 weeks).
/// Drives the dashboard hero ring; 0 means "no budget set".
final monthlyBudgetTotalProvider = Provider<int>((ref) {
  final budgets = ref.watch(budgetsProvider).value ?? const [];
  var total = 0;
  for (final b in budgets) {
    total += b.period == BudgetPeriod.monthly ? b.limitCents : b.limitCents * 4;
  }
  return total;
});

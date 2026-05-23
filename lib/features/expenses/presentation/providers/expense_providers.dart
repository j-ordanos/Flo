import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/session_provider.dart';
import '../../data/csv_export_service.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ExpenseRepositoryImpl(db.expenseDao);
});

final csvExportServiceProvider =
    Provider<CsvExportService>((ref) => const CsvExportService());

/// First day of the current month — the dashboard's reporting window.
final currentMonthProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final expensesProvider = StreamProvider.autoDispose<List<Expense>>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.watchExpenses(ref.watch(currentUserIdProvider));
});

final monthlyTotalProvider = StreamProvider.autoDispose<int>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.watchMonthlyTotal(
    ref.watch(currentUserIdProvider),
    ref.watch(currentMonthProvider),
  );
});

final categoryTotalsProvider =
    StreamProvider.autoDispose<Map<String, int>>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.watchTotalsByCategory(
    ref.watch(currentUserIdProvider),
    ref.watch(currentMonthProvider),
  );
});

final expenseByIdProvider =
    StreamProvider.autoDispose.family<Expense?, String>((ref, id) {
  return ref.watch(expenseRepositoryProvider).watchExpense(id);
});

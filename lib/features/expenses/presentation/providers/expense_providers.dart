import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/session_provider.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/csv_export_service.dart';
import '../../data/receipt_service.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ExpenseRepositoryImpl(db.expenseDao);
});

final csvExportServiceProvider =
    Provider<CsvExportService>((ref) => const CsvExportService());

final receiptServiceProvider = Provider<ReceiptService>(
  (ref) => ReceiptService(ref.watch(supabaseClientProvider)),
);

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

/// Previous calendar month's total — drives the dashboard trend chip.
final lastMonthTotalProvider = StreamProvider.autoDispose<int>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  final month = ref.watch(currentMonthProvider);
  final prev = DateTime(month.year, month.month - 1);
  return repo.watchMonthlyTotal(ref.watch(currentUserIdProvider), prev);
});

final expenseByIdProvider =
    StreamProvider.autoDispose.family<Expense?, String>((ref, id) {
  return ref.watch(expenseRepositoryProvider).watchExpense(id);
});

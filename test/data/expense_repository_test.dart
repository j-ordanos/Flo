import 'package:drift/native.dart';
import 'package:flo/core/database/app_database.dart';
import 'package:flo/core/enums/transaction_type.dart';
import 'package:flo/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:flo/features/expenses/domain/entities/expense.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ExpenseRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ExpenseRepositoryImpl(db.expenseDao);
  });
  tearDown(() => db.close());

  Expense expense({
    required String id,
    required int cents,
    DateTime? date,
    TransactionType type = TransactionType.expense,
  }) {
    final now = DateTime.utc(2026, 5, 1);
    return Expense(
      id: id,
      userId: 'u1',
      amountCents: cents,
      type: type,
      categoryId: 'food',
      date: date ?? now,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('add then watch returns the expense', () async {
    await repo.addExpense(expense(id: 'e1', cents: 1500));
    final list = await repo.watchExpenses('u1').first;
    expect(list, hasLength(1));
    expect(list.first.amountCents, 1500);
  });

  test('soft delete hides it from the active list', () async {
    await repo.addExpense(expense(id: 'e1', cents: 1000));
    await repo.deleteExpense('e1');
    expect(await repo.watchExpenses('u1').first, isEmpty);
  });

  test('monthly total sums only that month, excluding deletes', () async {
    await repo.addExpense(expense(id: 'e1', cents: 1000, date: DateTime.utc(2026, 5, 3)));
    await repo.addExpense(expense(id: 'e2', cents: 2500, date: DateTime.utc(2026, 5, 20)));
    await repo.addExpense(expense(id: 'e3', cents: 9999, date: DateTime.utc(2026, 4, 30)));
    final total = await repo.watchMonthlyTotal('u1', DateTime(2026, 5)).first;
    expect(total, 3500);
  });

  test('totals by category groups spend', () async {
    await repo.addExpense(expense(id: 'e1', cents: 1000, date: DateTime.utc(2026, 5, 3)));
    await repo.addExpense(expense(id: 'e2', cents: 500, date: DateTime.utc(2026, 5, 4)));
    final byCat = await repo.watchTotalsByCategory('u1', DateTime(2026, 5)).first;
    expect(byCat['food'], 1500);
  });

  test('income is excluded from spend totals but counted as income', () async {
    final d = DateTime.utc(2026, 5, 12);
    await repo.addExpense(expense(id: 'e1', cents: 1000, date: d));
    await repo.addExpense(expense(
        id: 'i1', cents: 5000, date: d, type: TransactionType.income));

    expect(await repo.watchMonthlyTotal('u1', DateTime(2026, 5)).first, 1000);
    expect(await repo.watchMonthlyIncome('u1', DateTime(2026, 5)).first, 5000);
    final byCat = await repo.watchTotalsByCategory('u1', DateTime(2026, 5)).first;
    expect(byCat['food'], 1000);
  });
}

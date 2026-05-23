import 'package:flo/features/budgets/domain/entities/budget.dart';
import 'package:flo/features/budgets/presentation/providers/budget_providers.dart';
import 'package:flo/features/categories/domain/entities/category.dart';
import 'package:flo/features/categories/presentation/providers/category_providers.dart';
import 'package:flo/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:flo/features/expenses/domain/entities/expense.dart';
import 'package:flo/features/expenses/presentation/providers/expense_providers.dart';
import 'package:flo/features/expenses/presentation/widgets/expense_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 5, 1);
  final food = Category(
    id: 'c1',
    userId: 'u',
    name: 'Food',
    icon: 'food',
    colorHex: 'F59E0B',
    createdAt: now,
    updatedAt: now,
  );

  testWidgets('shows empty state when there are no expenses', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expensesProvider
              .overrideWith((ref) => Stream.value(const <Expense>[])),
          monthlyTotalProvider.overrideWith((ref) => Stream.value(0)),
          categoryTotalsProvider
              .overrideWith((ref) => Stream.value(const <String, int>{})),
          categoriesProvider
              .overrideWith((ref) => Stream.value(const <Category>[])),
          budgetsProvider.overrideWith((ref) => Stream.value(const <Budget>[])),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Start tracking'), findsOneWidget);
    expect(find.byType(ExpenseTile), findsNothing);
  });

  testWidgets('lists recent expenses when present', (tester) async {
    final expense = Expense(
      id: 'e1',
      userId: 'u',
      amountCents: 1234,
      categoryId: 'c1',
      date: now,
      createdAt: now,
      updatedAt: now,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expensesProvider.overrideWith((ref) => Stream.value([expense])),
          monthlyTotalProvider.overrideWith((ref) => Stream.value(1234)),
          categoryTotalsProvider
              .overrideWith((ref) => Stream.value(const {'c1': 1234})),
          categoriesProvider.overrideWith((ref) => Stream.value([food])),
          budgetsProvider.overrideWith((ref) => Stream.value(const <Budget>[])),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recent'), findsOneWidget);
    expect(find.byType(ExpenseTile), findsOneWidget);
  });
}

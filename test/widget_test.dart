import 'package:flo/core/providers/preferences_provider.dart';
import 'package:flo/features/budgets/domain/entities/budget.dart';
import 'package:flo/features/budgets/presentation/providers/budget_providers.dart';
import 'package:flo/features/categories/domain/entities/category.dart';
import 'package:flo/features/categories/presentation/providers/category_providers.dart';
import 'package:flo/features/expenses/domain/entities/expense.dart';
import 'package:flo/features/expenses/presentation/providers/expense_providers.dart';
import 'package:flo/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App boots into the bottom-nav shell on Home', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        // Stub data + prefs so the boot test needs no platform plugins.
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          expensesProvider
              .overrideWith((ref) => Stream.value(const <Expense>[])),
          monthlyTotalProvider.overrideWith((ref) => Stream.value(0)),
          lastMonthTotalProvider.overrideWith((ref) => Stream.value(0)),
          categoriesProvider
              .overrideWith((ref) => Stream.value(const <Category>[])),
          budgetsProvider.overrideWith((ref) => Stream.value(const <Budget>[])),
        ],
        child: const FloApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Budgets'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}

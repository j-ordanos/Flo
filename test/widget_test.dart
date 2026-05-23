import 'package:flo/features/categories/domain/entities/category.dart';
import 'package:flo/features/categories/presentation/providers/category_providers.dart';
import 'package:flo/features/expenses/domain/entities/expense.dart';
import 'package:flo/features/expenses/presentation/providers/expense_providers.dart';
import 'package:flo/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boots into the bottom-nav shell on Home', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        // Stub the dashboard's data so the boot test needs no platform plugins.
        overrides: [
          expensesProvider
              .overrideWith((ref) => Stream.value(const <Expense>[])),
          monthlyTotalProvider.overrideWith((ref) => Stream.value(0)),
          categoriesProvider
              .overrideWith((ref) => Stream.value(const <Category>[])),
        ],
        child: const FloApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Shell renders with the four primary destinations.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Budgets'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}

import 'package:flo/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boots into the bottom-nav shell on Home', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FloApp()));
    await tester.pumpAndSettle();

    // Shell renders with the four primary destinations.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Budgets'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Budgets',
        icon: Icons.account_balance_wallet_outlined,
      );
}

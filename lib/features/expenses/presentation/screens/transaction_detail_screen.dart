import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({required this.expenseId, super.key});

  final String expenseId;

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Transaction',
        icon: Icons.receipt_long_outlined,
      );
}

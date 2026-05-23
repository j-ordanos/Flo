import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

class AddExpenseScreen extends StatelessWidget {
  const AddExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const PlaceholderScreen(title: 'Add expense', icon: Icons.add_card_outlined);
}

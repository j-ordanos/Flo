import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Welcome to Flo',
        icon: Icons.waving_hand_outlined,
      );
}

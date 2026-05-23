import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const PlaceholderScreen(title: 'Log in', icon: Icons.login_outlined);
}

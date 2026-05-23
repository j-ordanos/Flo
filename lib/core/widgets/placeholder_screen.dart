import 'package:flutter/material.dart';

/// Temporary scaffold shown until a feature screen is implemented.
///
/// Replaced phase-by-phase as real screens land.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.title,
    this.icon = Icons.construction_outlined,
    this.showAppBar = true,
    super.key,
  });

  final String title;
  final IconData icon;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: showAppBar ? AppBar(title: Text(title)) : null,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('$title — coming soon', style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

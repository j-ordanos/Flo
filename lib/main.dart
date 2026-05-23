import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/providers/preferences_provider.dart';
import 'core/providers/session_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/categories/presentation/providers/category_providers.dart';
import 'features/profile/presentation/providers/settings_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  // Initialize the active currency symbol from prefs before first paint.
  container.read(currencyProvider);
  // Seed default categories for the local user on first launch.
  final userId = container.read(currentUserIdProvider);
  await container.read(categoryRepositoryProvider).seedDefaultsIfEmpty(userId);

  runApp(
    UncontrolledProviderScope(container: container, child: const FloApp()),
  );
}

class FloApp extends ConsumerWidget {
  const FloApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    // Rebuild the tree when the currency changes so formatted amounts refresh.
    ref.watch(currencyProvider);

    return MaterialApp.router(
      title: 'Flo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/session_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/categories/presentation/providers/category_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  // Seed the default categories for the local user on first launch.
  // Auth (P5) will re-run this for the authenticated user.
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
    return MaterialApp.router(
      title: 'Flo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // User override (stored in SharedPreferences) is wired up in P3.
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}

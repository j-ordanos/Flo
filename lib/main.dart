import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_env.dart';
import 'core/providers/preferences_provider.dart';
import 'core/providers/session_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/categories/presentation/providers/category_providers.dart';
import 'features/notifications/presentation/providers/notification_providers.dart';
import 'features/profile/presentation/providers/settings_providers.dart';
import 'features/sync/presentation/providers/sync_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Connect to Supabase only when keys are configured; the app is fully usable
  // offline without them. Auth (P5) and sync (P6) build on this.
  if (AppEnv.hasSupabase) {
    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
    );
  }

  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  // Initialize the active currency symbol from prefs before first paint.
  container.read(currencyProvider);
  // In local-only mode, seed default categories now. In auth mode they're
  // seeded for the user on sign-in.
  if (!AppEnv.hasSupabase) {
    final userId = container.read(currentUserIdProvider);
    final categories = container.read(categoryRepositoryProvider);
    await categories.seedDefaultsIfEmpty(userId);
    await categories.refreshDefaultStyles(userId);
  }

  runApp(
    UncontrolledProviderScope(container: container, child: const FloApp()),
  );
}

class FloApp extends ConsumerStatefulWidget {
  const FloApp({super.key});

  @override
  ConsumerState<FloApp> createState() => _FloAppState();
}

class _FloAppState extends ConsumerState<FloApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Run post-sign-in side effects for any auth method (email or Google).
    if (AppEnv.hasSupabase) {
      ref.listenManual(authStateProvider, (_, next) {
        if (next.value?.event == AuthChangeEvent.signedIn) {
          ref.read(authControllerProvider).onAuthenticated();
        }
      });
    }
    // Prepare notifications up front so budget alerts can fire later.
    if (ref.read(pushEnabledProvider)) {
      ref.read(notificationServiceProvider).init();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(syncControllerProvider.notifier).requestSync();
    }
  }

  @override
  Widget build(BuildContext context) {
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

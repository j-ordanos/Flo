import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/budgets/presentation/screens/budgets_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/expenses/presentation/screens/transaction_detail_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../config/app_env.dart';
import '../constants/app_constants.dart';
import '../providers/preferences_provider.dart';
import '../widgets/main_shell.dart';
import 'app_routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Application router with an auth + onboarding guard.
///
/// When Supabase isn't configured the guard is inert and the app runs in
/// local-only mode (no gate).
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    refreshListenable: AppEnv.hasSupabase
        ? _GoRouterRefreshStream(
            Supabase.instance.client.auth.onAuthStateChange)
        : null,
    redirect: (context, state) {
      if (!AppEnv.hasSupabase) return null;

      final loggedIn = Supabase.instance.client.auth.currentUser != null;
      final onboarded =
          ref.read(sharedPreferencesProvider).getBool(kOnboardingSeenKey) ??
              false;
      final location = state.matchedLocation;
      final atOnboarding = location == AppRoutes.onboarding;
      final atAuth =
          location == AppRoutes.login || location == AppRoutes.signup;

      if (!onboarded && !atOnboarding) return AppRoutes.onboarding;
      if (onboarded && !loggedIn && !atAuth) return AppRoutes.login;
      if (loggedIn && (atAuth || atOnboarding)) return AppRoutes.home;
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.analytics,
                name: 'analytics',
                builder: (context, state) => const AnalyticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.budgets,
                name: 'budgets',
                builder: (context, state) => const BudgetsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.transactionDetail,
        name: 'transactionDetail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => TransactionDetailScreen(
          expenseId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
    ],
  );
});

/// Bridges a [Stream] to a [Listenable] so go_router re-evaluates redirects on
/// auth changes.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription =
        stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

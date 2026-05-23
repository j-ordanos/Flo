/// Centralized route paths and names used by `go_router`.
abstract final class AppRoutes {
  const AppRoutes._();

  // Auth / onboarding (outside the bottom-nav shell)
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';

  // Bottom-nav shell branches
  static const String home = '/';
  static const String analytics = '/analytics';
  static const String budgets = '/budgets';
  static const String profile = '/profile';

  // Modals / detail (root navigator)
  static const String addExpense = '/add';
  static const String transactionDetail = '/transaction/:id';

  static String transactionDetailPath(String id) => '/transaction/$id';
}

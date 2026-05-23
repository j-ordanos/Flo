import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/preferences_provider.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
});

/// Whether onboarding has been completed (persisted).
class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(sharedPreferencesProvider).getBool(kOnboardingSeenKey) ?? false;

  Future<void> complete() async {
    state = true;
    await ref.read(sharedPreferencesProvider).setBool(kOnboardingSeenKey, true);
  }
}

final onboardingSeenProvider =
    NotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);

/// Coordinates auth actions with their local side effects (data migration +
/// default-category seeding for the signed-in user).
class AuthController {
  AuthController(this._ref);

  final Ref _ref;

  Future<void> signIn(String email, String password) async {
    await _ref
        .read(authRepositoryProvider)
        .signInWithEmail(email: email, password: password);
    await _onAuthenticated();
  }

  /// Returns true when a session started immediately (email confirmation off),
  /// false when the user must confirm their email before signing in.
  Future<bool> signUp(String name, String email, String password) async {
    await _ref.read(authRepositoryProvider).signUpWithEmail(
          email: email,
          password: password,
          name: name,
        );
    if (Supabase.instance.client.auth.currentUser == null) return false;
    await _onAuthenticated();
    return true;
  }

  Future<void> signInWithGoogle() =>
      _ref.read(authRepositoryProvider).signInWithGoogle();

  Future<void> signOut() => _ref.read(authRepositoryProvider).signOut();

  Future<void> _onAuthenticated() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    await _ref.read(databaseProvider).reassignLocalUserData(userId);
    final categories = _ref.read(categoryRepositoryProvider);
    await categories.seedDefaultsIfEmpty(userId);
    await categories.refreshDefaultStyles(userId);
  }
}

final authControllerProvider = Provider<AuthController>(AuthController.new);

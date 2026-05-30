import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/preferences_provider.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../../features/sync/presentation/providers/sync_providers.dart';
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

final onboardingSeenProvider = NotifierProvider<OnboardingNotifier, bool>(
  OnboardingNotifier.new,
);

/// Coordinates auth actions with their local side effects (data migration +
/// default-category seeding for the signed-in user).
class AuthController {
  AuthController(this._ref);

  final Ref _ref;
  bool _runningPostSignIn = false;

  Future<void> signIn(String email, String password) => _ref
      .read(authRepositoryProvider)
      .signInWithEmail(email: email, password: password);

  /// Returns true when a session started immediately (email confirmation off),
  /// false when the user must confirm their email before signing in.
  Future<bool> signUp(String name, String email, String password) async {
    await _ref
        .read(authRepositoryProvider)
        .signUpWithEmail(email: email, password: password, name: name);
    return Supabase.instance.client.auth.currentUser != null;
  }

  Future<void> signInWithGoogle() =>
      _ref.read(authRepositoryProvider).signInWithGoogle();

  /// Lets the user into the app locally without an account. Data created as a
  /// guest migrates to their account on a later sign-in via [onAuthenticated].
  Future<void> continueAsGuest() =>
      _ref.read(sharedPreferencesProvider).setBool(kGuestModeKey, true);

  /// Signs out but keeps the app usable: drop back into local (guest) mode
  /// instead of a locked login screen. Cloud data reappears on next sign-in.
  Future<void> signOut() async {
    await _ref.read(sharedPreferencesProvider).setBool(kGuestModeKey, true);
    await _ref.read(authRepositoryProvider).signOut();
  }

  /// Local side effects to run whenever a user signs in (any method). Idempotent
  /// — migrates offline data to the user and ensures default categories exist.
  /// Guarded against re-entry: the `signedIn` auth event can fire more than once
  /// (sign-in, token refresh, session restore) and concurrent seeding caused
  /// duplicate categories.
  Future<void> onAuthenticated() async {
    if (_runningPostSignIn) return;
    _runningPostSignIn = true;
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final db = _ref.read(databaseProvider);
      await db.reassignLocalUserData(userId);
      // Repair legacy non-UUID category ids before anything tries to sync them.
      await db.migrateNonUuidCategoryIds(userId);
      final categories = _ref.read(categoryRepositoryProvider);
      await categories.seedDefaultsIfEmpty(userId);
      await categories.seedIncomeDefaultsIfMissing(userId);
      await categories.refreshDefaultStyles(userId);
      await db.dedupeDefaultCategories(userId);
    } finally {
      _runningPostSignIn = false;
    }
    // Ensure a sync is requested only after migrations and seeding are finished
    // so legacy non-UUID ids are corrected before any upload attempts.
    try {
      _ref.read(syncControllerProvider.notifier).requestSync();
    } catch (_) {
      // Best-effort; don't surface sync failures here.
    }
  }
}

final authControllerProvider = Provider<AuthController>(AuthController.new);

/// Authentication actions. Reactive auth state is exposed by
/// `authStateProvider` / `currentUserIdProvider` in core.
abstract interface class AuthRepository {
  /// Throws [Exception] (Supabase `AuthException`) on failure.
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  });

  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signInWithGoogle();

  Future<void> signOut();
}

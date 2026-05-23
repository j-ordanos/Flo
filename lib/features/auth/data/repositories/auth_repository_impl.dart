import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/auth_repository.dart';

/// [AuthRepository] backed by Supabase Auth. Sessions are persisted by the SDK.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signInWithGoogle() async {
    // Requires the Google provider enabled in Supabase + platform redirect setup.
    await _client.auth.signInWithOAuth(OAuthProvider.google);
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
}

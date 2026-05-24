import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
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
    // Browser-redirect (PKCE) flow. Requires the Google provider enabled in
    // Supabase, the redirect URL allow-listed, and the deep link registered on
    // Android/iOS. The SDK handles the callback and sets the session.
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kOAuthRedirect,
    );
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
}

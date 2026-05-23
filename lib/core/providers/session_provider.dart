import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_env.dart';
import '../constants/app_constants.dart';

/// Supabase auth state changes. Empty when Supabase isn't configured (the app
/// then runs in local-only mode).
final authStateProvider = StreamProvider<AuthState?>((ref) {
  if (!AppEnv.hasSupabase) return const Stream<AuthState?>.empty();
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// Owner id for local data: the signed-in user, or [kLocalUserId] when signed
/// out or running without Supabase.
final currentUserIdProvider = Provider<String>((ref) {
  if (!AppEnv.hasSupabase) return kLocalUserId;
  ref.watch(authStateProvider); // re-evaluate on sign-in / sign-out
  return Supabase.instance.client.auth.currentUser?.id ?? kLocalUserId;
});

/// The signed-in Supabase user (null when signed out or Supabase is disabled).
final currentUserProvider = Provider<User?>((ref) {
  if (!AppEnv.hasSupabase) return null;
  ref.watch(authStateProvider);
  return Supabase.instance.client.auth.currentUser;
});

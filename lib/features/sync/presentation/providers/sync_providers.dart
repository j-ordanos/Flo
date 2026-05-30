import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_env.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/preferences_provider.dart';
import '../../../../core/providers/session_provider.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/supabase_sync_remote.dart';
import '../../data/sync_service.dart';
import '../../domain/sync_remote.dart';

enum SyncPhase { idle, syncing, synced, error }

/// The last sync error message (null when the last sync succeeded). Surfaced in
/// the UI so failures aren't silent — invaluable for diagnosing why a row stays
/// "pending" (e.g. a Supabase column that hasn't been migrated yet).
class SyncErrorNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? message) => state = message;
}

final syncErrorProvider =
    NotifierProvider<SyncErrorNotifier, String?>(SyncErrorNotifier.new);

final syncRemoteProvider = Provider<SyncRemote>(
  (ref) => SupabaseSyncRemote(ref.watch(supabaseClientProvider)),
);

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    db: ref.watch(databaseProvider),
    remote: ref.watch(syncRemoteProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  );
});

/// Orchestrates sync: runs on sign-in, connectivity restored, app foreground,
/// and after local writes (debounced). Exposes the current [SyncPhase].
class SyncController extends Notifier<SyncPhase> {
  Timer? _debounce;

  @override
  SyncPhase build() {
    if (!AppEnv.hasSupabase) return SyncPhase.idle;

    ref.listen(connectivityProvider, (_, next) {
      if (next.value ?? false) requestSync();
    });
    ref.listen(authStateProvider, (_, _) => requestSync());

    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(requestSync);
    return SyncPhase.idle;
  }

  /// Debounced sync request — safe to call liberally (e.g. after each write).
  void requestSync() {
    if (!AppEnv.hasSupabase) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _run);
  }

  Future<void> _run() async {
    final online = ref.read(connectivityProvider).value ?? false;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (!online || userId == null || state == SyncPhase.syncing) return;

    state = SyncPhase.syncing;
    try {
      await ref.read(syncServiceProvider).sync(userId);
      ref.read(syncErrorProvider.notifier).set(null);
      state = SyncPhase.synced;
    } catch (e) {
      ref.read(syncErrorProvider.notifier).set(e.toString());
      state = SyncPhase.error;
    }
  }
}

final syncControllerProvider =
    NotifierProvider<SyncController, SyncPhase>(SyncController.new);

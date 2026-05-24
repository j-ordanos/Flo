import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/sync_remote.dart';

/// [SyncRemote] backed by Supabase Postgrest. RLS scopes every query to the
/// signed-in user; we also filter by `user_id` explicitly.
class SupabaseSyncRemote implements SyncRemote {
  SupabaseSyncRemote(this._client);

  final SupabaseClient _client;

  @override
  Future<void> upsert(String table, List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await _client.from(table).upsert(rows);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSince(
    String table,
    String userId,
    DateTime? since,
  ) async {
    final base = _client.from(table).select().eq('user_id', userId);
    final filtered = since == null
        ? base
        : base.gt('updated_at', since.toUtc().toIso8601String());
    final data = await filtered.order('updated_at');
    return data.cast<Map<String, dynamic>>();
  }
}

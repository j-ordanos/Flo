/// Transport for sync: upsert local rows and fetch remote changes since a
/// cursor. Abstracted so the sync engine can be unit-tested without Supabase.
abstract interface class SyncRemote {
  Future<void> upsert(String table, List<Map<String, dynamic>> rows);

  /// Rows for [userId] with `updated_at` strictly after [since] (all when null),
  /// ordered by `updated_at` ascending.
  Future<List<Map<String, dynamic>>> fetchSince(
    String table,
    String userId,
    DateTime? since,
  );
}

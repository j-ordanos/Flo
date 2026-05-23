/// Local sync state of a row.
///
/// `pending` rows are flushed to the cloud by the sync engine (P6);
/// `synced` rows are up to date with the server.
enum SyncStatus { synced, pending }

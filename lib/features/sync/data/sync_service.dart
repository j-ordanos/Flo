import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/app_database.dart';
import '../../../core/enums/sync_status.dart';
import '../domain/sync_remote.dart';
import 'sync_mappers.dart';

/// Two-way sync: push locally-changed rows, then pull remote changes since a
/// per-table cursor. Conflicts resolve last-write-wins on the server's
/// `updated_at`; unsynced local edits are never clobbered.
class SyncService {
  SyncService({
    required AppDatabase db,
    required SyncRemote remote,
    required SharedPreferences prefs,
  })  : _db = db,
        _remote = remote,
        _prefs = prefs;

  final AppDatabase _db;
  final SyncRemote _remote;
  final SharedPreferences _prefs;

  static const _maxAttempts = 3;

  /// Runs a full sync for [userId] with exponential backoff on transient
  /// failures. Throws if all attempts fail.
  Future<void> sync(String userId) async {
    for (var attempt = 0;; attempt++) {
      try {
        await _push(userId);
        await _pull(userId);
        // Collapse any duplicate default categories that the pull may have
        // brought down from older installs, then push the resulting deletes.
        if (await _db.dedupeDefaultCategories(userId)) {
          await _push(userId);
        }
        return;
      } catch (_) {
        if (attempt >= _maxAttempts - 1) rethrow;
        await Future<void>.delayed(Duration(seconds: 1 << attempt));
      }
    }
  }

  Future<void> _push(String userId) async {
    // Push each table independently so a schema/permission problem on one (e.g.
    // a column the server hasn't migrated yet) doesn't block the others. The
    // first error is rethrown so the caller can retry and surface it.
    Object? firstError;

    try {
      final categories = await _db.categoryDao.getPending(userId);
      if (categories.isNotEmpty) {
        await _remote.upsert(
            'categories', categories.map(categoryToJson).toList());
        await _db.categoryDao.markSynced([for (final c in categories) c.id]);
      }
    } catch (e) {
      firstError ??= e;
    }

    try {
      final expenses = await _db.expenseDao.getPending(userId);
      if (expenses.isNotEmpty) {
        await _remote.upsert('expenses', expenses.map(expenseToJson).toList());
        await _db.expenseDao.markSynced([for (final e in expenses) e.id]);
      }
    } catch (e) {
      firstError ??= e;
    }

    try {
      final budgets = await _db.budgetDao.getPending(userId);
      if (budgets.isNotEmpty) {
        await _remote.upsert('budgets', budgets.map(budgetToJson).toList());
        await _db.budgetDao.markSynced([for (final b in budgets) b.id]);
      }
    } catch (e) {
      firstError ??= e;
    }

    if (firstError != null) throw firstError;
  }

  Future<void> _pull(String userId) async {
    await _pullTable<CategoryRow>(
      table: 'categories',
      userId: userId,
      fromJson: categoryFromJson,
      findLocal: _db.categoryDao.findById,
      apply: _db.categoryDao.upsert,
      updatedAt: (r) => r.updatedAt,
      isSynced: (r) => r.syncStatus == SyncStatus.synced,
    );
    await _pullTable<ExpenseRow>(
      table: 'expenses',
      userId: userId,
      fromJson: expenseFromJson,
      findLocal: _db.expenseDao.findById,
      apply: _db.expenseDao.upsert,
      updatedAt: (r) => r.updatedAt,
      isSynced: (r) => r.syncStatus == SyncStatus.synced,
    );
    await _pullTable<BudgetRow>(
      table: 'budgets',
      userId: userId,
      fromJson: budgetFromJson,
      findLocal: _db.budgetDao.findById,
      apply: _db.budgetDao.upsert,
      updatedAt: (r) => r.updatedAt,
      isSynced: (r) => r.syncStatus == SyncStatus.synced,
    );
  }

  Future<void> _pullTable<R>({
    required String table,
    required String userId,
    required R Function(Map<String, dynamic>) fromJson,
    required Future<R?> Function(String id) findLocal,
    required Future<void> Function(R row) apply,
    required DateTime Function(R row) updatedAt,
    required bool Function(R row) isSynced,
  }) async {
    final since = _cursor(table, userId);
    final rows = await _remote.fetchSince(table, userId, since);
    var maxUpdated = since;
    for (final json in rows) {
      final remote = fromJson(json);
      final local = await findLocal(json['id'] as String);
      // Apply when there's no local row, or the local copy is already synced
      // and older than the remote (don't clobber pending local edits).
      if (local == null ||
          (isSynced(local) && updatedAt(remote).isAfter(updatedAt(local)))) {
        await apply(remote);
      }
      final ts = updatedAt(remote);
      if (maxUpdated == null || ts.isAfter(maxUpdated)) maxUpdated = ts;
    }
    if (maxUpdated != null) await _setCursor(table, userId, maxUpdated);
  }

  DateTime? _cursor(String table, String userId) {
    final raw = _prefs.getString(_cursorKey(table, userId));
    return raw == null ? null : DateTime.parse(raw);
  }

  Future<void> _setCursor(String table, String userId, DateTime value) =>
      _prefs.setString(_cursorKey(table, userId), value.toUtc().toIso8601String());

  String _cursorKey(String table, String userId) => 'sync_cursor_${userId}_$table';
}

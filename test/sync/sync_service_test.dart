import 'package:drift/native.dart';
import 'package:flo/core/database/app_database.dart';
import 'package:flo/core/enums/sync_status.dart';
import 'package:flo/core/enums/transaction_type.dart';
import 'package:flo/features/sync/data/sync_mappers.dart';
import 'package:flo/features/sync/data/sync_service.dart';
import 'package:flo/features/sync/domain/sync_remote.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory [SyncRemote] for tests.
class FakeRemote implements SyncRemote {
  final Map<String, Map<String, Map<String, dynamic>>> store = {};

  @override
  Future<void> upsert(String table, List<Map<String, dynamic>> rows) async {
    final t = store.putIfAbsent(table, () => {});
    for (final r in rows) {
      t[r['id'] as String] = Map<String, dynamic>.from(r);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSince(
      String table, String userId, DateTime? since) async {
    final rows = (store[table] ?? {}).values.where((r) {
      if (r['user_id'] != userId) return false;
      if (since == null) return true;
      return DateTime.parse(r['updated_at'] as String).isAfter(since);
    }).toList()
      ..sort((a, b) => DateTime.parse(a['updated_at'] as String)
          .compareTo(DateTime.parse(b['updated_at'] as String)));
    return rows.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}

void main() {
  late AppDatabase db;
  late FakeRemote remote;
  late SyncService service;

  ExpenseRow expense({
    required String id,
    int cents = 1500,
    DateTime? updatedAt,
    SyncStatus status = SyncStatus.pending,
  }) {
    final now = DateTime.utc(2026, 5, 1);
    return ExpenseRow(
      id: id,
      userId: 'u',
      amountCents: cents,
      type: TransactionType.expense,
      categoryId: 'food',
      date: now,
      createdAt: now,
      updatedAt: updatedAt ?? now,
      syncStatus: status,
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    db = AppDatabase(NativeDatabase.memory());
    remote = FakeRemote();
    service = SyncService(db: db, remote: remote, prefs: prefs);
  });
  tearDown(() => db.close());

  test('expense mapper round-trips and marks synced', () {
    final row = expense(id: 'e1', cents: 4299);
    final back = expenseFromJson(expenseToJson(row));
    expect(back.id, row.id);
    expect(back.amountCents, 4299);
    expect(back.date, row.date);
    expect(back.syncStatus, SyncStatus.synced);
  });

  test('push uploads pending rows and marks them synced', () async {
    await db.expenseDao.upsert(expense(id: 'e1'));
    await service.sync('u');

    expect(remote.store['expenses']!.containsKey('e1'), isTrue);
    final local = await db.expenseDao.findById('e1');
    expect(local!.syncStatus, SyncStatus.synced);
  });

  test('pull downloads new remote rows', () async {
    remote.store['expenses'] = {
      'e2': expenseToJson(expense(
        id: 'e2',
        cents: 2000,
        updatedAt: DateTime.utc(2026, 5, 2),
        status: SyncStatus.synced,
      )),
    };
    await service.sync('u');

    final e2 = await db.expenseDao.findById('e2');
    expect(e2, isNotNull);
    expect(e2!.amountCents, 2000);
    expect(e2.syncStatus, SyncStatus.synced);
  });

  test('pull does not clobber a newer local synced row', () async {
    // Local already synced and newer than the remote copy.
    await db.expenseDao.upsert(expense(
      id: 'e3',
      cents: 9999,
      updatedAt: DateTime.utc(2026, 5, 10),
      status: SyncStatus.synced,
    ));
    remote.store['expenses'] = {
      'e3': expenseToJson(expense(
        id: 'e3',
        cents: 1,
        updatedAt: DateTime.utc(2026, 5, 1),
        status: SyncStatus.synced,
      )),
    };
    await service.sync('u');

    final e3 = await db.expenseDao.findById('e3');
    expect(e3!.amountCents, 9999); // local kept
  });
}

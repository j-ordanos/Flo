import 'package:drift/native.dart';
import 'package:flo/core/constants/app_constants.dart';
import 'package:flo/core/database/app_database.dart';
import 'package:flo/core/enums/sync_status.dart';
import 'package:flo/core/enums/transaction_type.dart';
import 'package:flo/features/categories/data/repositories/category_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late CategoryRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = CategoryRepositoryImpl(db.categoryDao);
  });
  tearDown(() => db.close());

  CategoryRow cat(String id, String icon) {
    final now = DateTime.utc(2026, 5, 1);
    return CategoryRow(
      id: id,
      userId: 'u1',
      name: icon,
      icon: icon,
      colorHex: 'F59E0B',
      isDefault: true,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.synced,
    );
  }

  test('seeding uses deterministic ids and is idempotent', () async {
    await repo.seedDefaultsIfEmpty('u1');
    final first = await db.categoryDao.getCategories('u1');
    expect(first, isNotEmpty);
    expect(
      first.any((c) => c.id == defaultCategoryId('u1', 'expense', 'food')),
      isTrue,
    );

    // Re-seeding does nothing (count > 0) and ids stay stable.
    await repo.seedDefaultsIfEmpty('u1');
    final second = await db.categoryDao.getCategories('u1');
    expect(second.length, first.length);
  });

  test('dedupe collapses duplicate defaults and repoints expenses', () async {
    // Two "Food" defaults with different ids (the old random-id bug).
    final canonical = defaultCategoryId('u1', 'expense', 'food');
    await db.categoryDao.upsert(cat(canonical, 'food'));
    await db.categoryDao.upsert(cat('random-dup-id', 'food'));

    // An expense points at the duplicate.
    final now = DateTime.utc(2026, 5, 2);
    await db.expenseDao.upsert(ExpenseRow(
      id: 'e1',
      userId: 'u1',
      amountCents: 1000,
      type: TransactionType.expense,
      categoryId: 'random-dup-id',
      date: now,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.synced,
    ));

    final changed = await db.dedupeDefaultCategories('u1');
    expect(changed, isTrue);

    // Only the canonical survivor remains visible.
    final live = await db.categoryDao.getCategories('u1');
    expect(live.where((c) => c.icon == 'food'), hasLength(1));
    expect(live.single.id, canonical);

    // The expense was repointed to the survivor and marked pending.
    final e = await db.expenseDao.findById('e1');
    expect(e!.categoryId, canonical);
    expect(e.syncStatus, SyncStatus.pending);

    // Idempotent: a second pass changes nothing.
    expect(await db.dedupeDefaultCategories('u1'), isFalse);
  });
}

import 'package:drift/native.dart';
import 'package:flo/core/database/app_database.dart';
import 'package:flo/core/enums/category_kind.dart';
import 'package:flo/core/enums/sync_status.dart';
import 'package:flo/features/categories/data/default_categories.dart';
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

  test('seeds expense + income defaults once and is idempotent', () async {
    await repo.seedDefaultsIfEmpty('u1');
    var cats = await repo.getCategories('u1');
    expect(cats, hasLength(13)); // 7 expense + 6 income
    expect(cats.every((c) => c.isDefault), isTrue);
    expect(cats.where((c) => c.kind == CategoryKind.income), hasLength(6));

    await repo.seedDefaultsIfEmpty('u1');
    cats = await repo.getCategories('u1');
    expect(cats, hasLength(13));
  });

  test('seedIncomeDefaultsIfMissing backfills only income, idempotently',
      () async {
    // Simulate a pre-income user: expense defaults only.
    final now = DateTime.utc(2026, 5, 1);
    for (final d in kDefaultCategories) {
      await db.categoryDao.upsert(CategoryRow(
        id: 'old_${d.icon}',
        userId: 'u1',
        name: d.name,
        icon: d.icon,
        colorHex: d.colorHex,
        kind: CategoryKind.expense,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.synced,
      ));
    }
    expect((await repo.getCategories('u1')), hasLength(7));

    await repo.seedIncomeDefaultsIfMissing('u1');
    expect(
      (await repo.getCategories('u1'))
          .where((c) => c.kind == CategoryKind.income),
      hasLength(6),
    );

    // Idempotent.
    await repo.seedIncomeDefaultsIfMissing('u1');
    expect(
      (await repo.getCategories('u1'))
          .where((c) => c.kind == CategoryKind.income),
      hasLength(6),
    );
  });
}

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

  test('seeds 7 defaults once and is idempotent', () async {
    await repo.seedDefaultsIfEmpty('u1');
    var cats = await repo.getCategories('u1');
    expect(cats, hasLength(7));
    expect(cats.every((c) => c.isDefault), isTrue);

    await repo.seedDefaultsIfEmpty('u1');
    cats = await repo.getCategories('u1');
    expect(cats, hasLength(7));
  });
}

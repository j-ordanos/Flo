import 'package:drift/drift.dart';

import '../../enums/sync_status.dart';
import '../app_database.dart';
import '../tables/categories.dart';

part 'category_dao.g.dart';

/// Data access for [Categories]. All reads exclude soft-deleted rows.
@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase> with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Stream<List<CategoryRow>> watchCategories(String userId) =>
      (select(categories)
            ..where((c) => c.userId.equals(userId) & c.deletedAt.isNull())
            ..orderBy([(c) => OrderingTerm.asc(c.name)]))
          .watch();

  Future<List<CategoryRow>> getCategories(String userId) =>
      (select(categories)
            ..where((c) => c.userId.equals(userId) & c.deletedAt.isNull()))
          .get();

  Future<CategoryRow?> findById(String id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<int> countForUser(String userId) async {
    final count = categories.id.count();
    final row = await (selectOnly(categories)
          ..addColumns([count])
          ..where(categories.userId.equals(userId) &
              categories.deletedAt.isNull()))
        .getSingle();
    return row.read(count) ?? 0;
  }

  Future<void> upsert(CategoryRow row) =>
      into(categories).insertOnConflictUpdate(row);

  Future<void> insertAll(List<CategoryRow> rows) =>
      batch((b) => b.insertAll(categories, rows, mode: InsertMode.insertOrIgnore));

  Future<void> softDelete(String id, DateTime when) =>
      (update(categories)..where((c) => c.id.equals(id))).write(
        CategoriesCompanion(
          deletedAt: Value(when),
          updatedAt: Value(when),
          syncStatus: const Value(SyncStatus.pending),
        ),
      );
}

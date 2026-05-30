import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/category_dao.dart';
import '../../../../core/enums/sync_status.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../default_categories.dart';
import '../mappers/category_mapper.dart';

/// Local-first [CategoryRepository].
class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._dao);

  final CategoryDao _dao;

  @override
  Future<void> seedDefaultsIfEmpty(String userId) async {
    if (await _dao.countForUser(userId) > 0) return;
    final now = DateTime.now().toUtc();
    final rows = [
      for (final d in kAllDefaultCategories)
        CategoryRow(
          id: defaultCategoryId(userId, d.kind.name, d.icon),
          userId: userId,
          name: d.name,
          icon: d.icon,
          colorHex: d.colorHex,
          kind: d.kind,
          isDefault: true,
          createdAt: now,
          updatedAt: now,
          syncStatus: SyncStatus.pending,
        ),
    ];
    await _dao.insertAll(rows);
  }

  @override
  Future<void> seedIncomeDefaultsIfMissing(String userId) async {
    if (await _dao.countForUserAndKind(userId, CategoryKind.income) > 0) return;
    final now = DateTime.now().toUtc();
    final rows = [
      for (final d in kDefaultIncomeCategories)
        CategoryRow(
          id: defaultCategoryId(userId, d.kind.name, d.icon),
          userId: userId,
          name: d.name,
          icon: d.icon,
          colorHex: d.colorHex,
          kind: d.kind,
          isDefault: true,
          createdAt: now,
          updatedAt: now,
          syncStatus: SyncStatus.pending,
        ),
    ];
    await _dao.insertAll(rows);
  }

  @override
  Future<void> refreshDefaultStyles(String userId) async {
    for (final d in kAllDefaultCategories) {
      await _dao.setDefaultColor(userId, d.kind, d.icon, d.colorHex);
    }
  }

  @override
  Stream<List<Category>> watchCategories(String userId) => _dao
      .watchCategories(userId)
      .map((rows) => rows.map((r) => r.toEntity()).toList());

  @override
  Future<List<Category>> getCategories(String userId) async =>
      (await _dao.getCategories(userId)).map((r) => r.toEntity()).toList();

  @override
  Future<void> addCategory(Category category) => _dao.upsert(category.toRow());

  @override
  Future<void> updateCategory(Category category) =>
      _dao.upsert(category.toRow());

  @override
  Future<void> deleteCategory(String id) =>
      _dao.softDelete(id, DateTime.now().toUtc());
}

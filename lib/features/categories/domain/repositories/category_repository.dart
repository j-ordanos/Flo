import '../entities/category.dart';

/// Local-first category access.
abstract interface class CategoryRepository {
  /// Creates the default category set for [userId] if none exist yet.
  Future<void> seedDefaultsIfEmpty(String userId);

  /// Backfills default income categories for users who were seeded before income
  /// existed (no-op if they already have any income category).
  Future<void> seedIncomeDefaultsIfMissing(String userId);

  /// Aligns existing default categories with the canonical color palette.
  Future<void> refreshDefaultStyles(String userId);

  Stream<List<Category>> watchCategories(String userId);
  Future<List<Category>> getCategories(String userId);
  Future<void> addCategory(Category category);
  Future<void> updateCategory(Category category);

  /// Soft delete (sets `deletedAt`).
  Future<void> deleteCategory(String id);
}

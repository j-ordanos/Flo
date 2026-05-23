import '../../../../core/database/app_database.dart';
import '../../domain/entities/category.dart';

/// Drift row → domain entity.
extension CategoryRowMapper on CategoryRow {
  Category toEntity() => Category(
        id: id,
        userId: userId,
        name: name,
        icon: icon,
        colorHex: colorHex,
        isDefault: isDefault,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
        syncStatus: syncStatus,
      );
}

/// Domain entity → Drift row.
extension CategoryEntityMapper on Category {
  CategoryRow toRow() => CategoryRow(
        id: id,
        userId: userId,
        name: name,
        icon: icon,
        colorHex: colorHex,
        isDefault: isDefault,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
        syncStatus: syncStatus,
      );
}

import '../../../../core/database/app_database.dart';
import '../../domain/entities/budget.dart';

/// Drift row → domain entity.
extension BudgetRowMapper on BudgetRow {
  Budget toEntity() => Budget(
        id: id,
        userId: userId,
        categoryId: categoryId,
        limitCents: limitCents,
        period: period,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
        syncStatus: syncStatus,
      );
}

/// Domain entity → Drift row.
extension BudgetEntityMapper on Budget {
  BudgetRow toRow() => BudgetRow(
        id: id,
        userId: userId,
        categoryId: categoryId,
        limitCents: limitCents,
        period: period,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
        syncStatus: syncStatus,
      );
}

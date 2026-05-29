import '../../../../core/database/app_database.dart';
import '../../domain/entities/expense.dart';

/// Drift row → domain entity.
extension ExpenseRowMapper on ExpenseRow {
  Expense toEntity() => Expense(
        id: id,
        userId: userId,
        amountCents: amountCents,
        type: type,
        categoryId: categoryId,
        merchant: merchant,
        note: note,
        receiptPath: receiptPath,
        date: date,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
        syncStatus: syncStatus,
      );
}

/// Domain entity → Drift row.
extension ExpenseEntityMapper on Expense {
  ExpenseRow toRow() => ExpenseRow(
        id: id,
        userId: userId,
        amountCents: amountCents,
        type: type,
        categoryId: categoryId,
        merchant: merchant,
        note: note,
        receiptPath: receiptPath,
        date: date,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
        syncStatus: syncStatus,
      );
}

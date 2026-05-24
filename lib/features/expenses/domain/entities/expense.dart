import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/enums/sync_status.dart';

part 'expense.freezed.dart';

/// A single spend. Amount is in integer cents; [deletedAt] marks a soft delete.
@freezed
abstract class Expense with _$Expense {
  const factory Expense({
    required String id,
    required String userId,
    required int amountCents,
    required String categoryId,
    required DateTime date,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? merchant,
    String? note,
    String? receiptPath,
    DateTime? deletedAt,
    @Default(SyncStatus.pending) SyncStatus syncStatus,
  }) = _Expense;
}

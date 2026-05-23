import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/enums/budget_period.dart';
import '../../../../core/enums/sync_status.dart';

part 'budget.freezed.dart';

/// A spending limit for a category over a [period]. Limit is integer cents.
@freezed
abstract class Budget with _$Budget {
  const factory Budget({
    required String id,
    required String userId,
    required String categoryId,
    required int limitCents,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(BudgetPeriod.monthly) BudgetPeriod period,
    DateTime? deletedAt,
    @Default(SyncStatus.pending) SyncStatus syncStatus,
  }) = _Budget;
}

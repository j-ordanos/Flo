import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/enums/sync_status.dart';

part 'category.freezed.dart';

/// A spending category. [icon] is a stable key resolved to an `IconData` by the
/// UI; [colorHex] is an `RRGGBB` string.
@freezed
abstract class Category with _$Category {
  const factory Category({
    required String id,
    required String userId,
    required String name,
    required String icon,
    required String colorHex,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool isDefault,
    DateTime? deletedAt,
    @Default(SyncStatus.pending) SyncStatus syncStatus,
  }) = _Category;
}

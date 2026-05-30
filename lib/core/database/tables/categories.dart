import 'package:drift/drift.dart';

import '../../enums/category_kind.dart';
import '../../enums/sync_status.dart';

/// Spending categories. `icon` stores a stable key resolved to an `IconData`
/// in the UI; `colorHex` is an `AARRGGBB`/`RRGGBB` hex string.
@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()(); // client-generated UUID v4
  TextColumn get userId => text().named('user_id')();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  TextColumn get colorHex => text().named('color_hex')();
  TextColumn get kind => textEnum<CategoryKind>()
      .withDefault(const Constant('expense'))();
  BoolColumn get isDefault =>
      boolean().named('is_default').withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();
  TextColumn get syncStatus => textEnum<SyncStatus>()
      .named('sync_status')
      .withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

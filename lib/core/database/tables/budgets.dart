import 'package:drift/drift.dart';

import '../../enums/budget_period.dart';
import '../../enums/sync_status.dart';

/// Per-category spending limits. UI and repository land in P3; the table is
/// defined now so the schema is complete (avoids a later migration).
@DataClassName('BudgetRow')
class Budgets extends Table {
  TextColumn get id => text()(); // client-generated UUID v4
  TextColumn get userId => text().named('user_id')();
  TextColumn get categoryId => text().named('category_id')();
  IntColumn get limitCents => integer().named('limit_cents')();
  TextColumn get period => textEnum<BudgetPeriod>()
      .withDefault(const Constant('monthly'))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();
  TextColumn get syncStatus => textEnum<SyncStatus>()
      .named('sync_status')
      .withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

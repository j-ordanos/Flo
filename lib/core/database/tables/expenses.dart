import 'package:drift/drift.dart';

import '../../enums/sync_status.dart';
import '../../enums/transaction_type.dart';

/// Expense rows. Money is stored as integer cents; deletes are soft
/// (`deletedAt`) so they can propagate during sync.
@DataClassName('ExpenseRow')
class Expenses extends Table {
  TextColumn get id => text()(); // client-generated UUID v4
  TextColumn get userId => text().named('user_id')();
  IntColumn get amountCents => integer().named('amount_cents')();
  TextColumn get type => textEnum<TransactionType>()
      .withDefault(const Constant('expense'))();
  TextColumn get categoryId => text().named('category_id')();
  TextColumn get merchant => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get receiptPath => text().named('receipt_path').nullable()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();
  TextColumn get syncStatus => textEnum<SyncStatus>()
      .named('sync_status')
      .withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

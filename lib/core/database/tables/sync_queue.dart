import 'package:drift/drift.dart';

import '../../enums/sync_operation.dart';

/// Outbox of local mutations awaiting upload (processed in P6).
@DataClassName('SyncQueueRow')
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get targetTable => text().named('table_name')();
  TextColumn get recordId => text().named('record_id')();
  TextColumn get operation => textEnum<SyncOperation>()();
  TextColumn get payloadJson => text().named('payload_json')();
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().named('last_error').nullable()();
}

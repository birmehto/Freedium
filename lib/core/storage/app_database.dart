import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// A single generic row storing JSON-encoded values.
class KvRows extends Table {
  TextColumn get key => text().withLength(min: 1, max: 255)();
  TextColumn get jsonValue => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// The app's SQLite database, managed by Drift.
///
/// Preferences and library data both flow through the [KvRows] table via a
/// [DriftKeyValueStore] so reads stay synchronous while every write is
/// persisted asynchronously through Drift/SQLite.
@DriftDatabase(tables: [KvRows])
class AppDatabase extends _$AppDatabase {
  /// Opens the on-device database (Android/iOS/desktop).
  AppDatabase.open() : super(driftDatabase(name: 'freedium'));

  /// For the supplied executor (tests use an in-memory database).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;
}

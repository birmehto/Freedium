import 'dart:convert';

import 'app_database.dart';

/// Minimal persistence contract shared by every store.
///
/// Production uses [DriftKeyValueStore].
/// Tests or temporary usage can use [MemoryKeyValueStore].
abstract class KeyValueStore {
  dynamic read(String key);

  Future<void> write(String key, dynamic value);

  Future<void> remove(String key);

  Iterable<String> getKeys();
}

/// Drift/SQLite-backed [KeyValueStore].
///
/// Values are JSON-encoded and stored in the `kvRows` table.
///
/// A memory cache keeps reads synchronous, while writes are persisted
/// asynchronously through Drift.
class DriftKeyValueStore implements KeyValueStore {
  DriftKeyValueStore(this._database);

  final AppDatabase _database;

  final Map<String, dynamic> _cache = {};

  bool _loaded = false;

  /// Loads all persisted values into the in-memory cache.
  ///
  /// Call this once after creating the store and before using [read].
  Future<void> init() async {
    if (_loaded) {
      return;
    }

    final rows = await _database.select(_database.kvRows).get();

    for (final row in rows) {
      try {
        _cache[row.key] = jsonDecode(row.jsonValue);
      } catch (_) {
        // Ignore invalid persisted JSON rather than preventing the
        // entire key-value store from loading.
      }
    }

    _loaded = true;
  }

  /// Closes the underlying database.
  Future<void> close() {
    return _database.close();
  }

  @override
  dynamic read(String key) {
    return _cache[key];
  }

  @override
  Future<void> write(String key, dynamic value) async {
    // Update memory first so subsequent reads immediately see the value.
    _cache[key] = value;

    final jsonValue = jsonEncode(value);

    await _database
        .into(_database.kvRows)
        .insertOnConflictUpdate(
          KvRowsCompanion.insert(key: key, jsonValue: jsonValue),
        );
  }

  @override
  Future<void> remove(String key) async {
    // Remove from cache immediately.
    _cache.remove(key);

    // Remove from persistent storage.
    await (_database.delete(
      _database.kvRows,
    )..where((table) => table.key.equals(key))).go();
  }

  @override
  Iterable<String> getKeys() {
    return _cache.keys;
  }
}

/// In-memory [KeyValueStore].
///
/// Useful for:
/// - Unit tests
/// - Widget tests
/// - Temporary storage
/// - Running code before the database is initialized
class MemoryKeyValueStore implements KeyValueStore {
  final Map<String, dynamic> _data = {};

  @override
  dynamic read(String key) {
    return _data[key];
  }

  @override
  Future<void> write(String key, dynamic value) async {
    _data[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }

  @override
  Iterable<String> getKeys() {
    return _data.keys;
  }
}

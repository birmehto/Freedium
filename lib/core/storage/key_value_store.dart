import 'dart:convert';

import '../utils/app_log.dart';
import 'app_database.dart';

/// Minimal persistence contract shared by every store.
///
/// Production uses [DriftKeyValueStore].
/// Tests use [MemoryKeyValueStore].
abstract interface class KeyValueStore {
  /// Synchronous read from the write-through cache.
  dynamic read(String key);

  /// Persists [value], which must be JSON-encodable.
  Future<void> write(String key, dynamic value);

  Future<void> remove(String key);

  Iterable<String> getKeys();
}

/// Drift/SQLite-backed [KeyValueStore].
///
/// Values are JSON-encoded and stored in the `kvRows` table. A memory cache
/// keeps reads synchronous, while writes are persisted through Drift.
///
/// Writes are chained onto a single queue so concurrent callers (for example a
/// slider dragging font size while the reader is caching metadata) can never
/// interleave, and a failed write is logged instead of surfacing as an
/// unhandled async error.
class DriftKeyValueStore implements KeyValueStore {
  DriftKeyValueStore(this._database);

  final AppDatabase _database;

  final Map<String, dynamic> _cache = {};

  bool _loaded = false;
  Future<void> _writeQueue = Future<void>.value();

  /// Loads all persisted values into the in-memory cache.
  ///
  /// Must be awaited once before [read] is used.
  Future<void> init() async {
    if (_loaded) return;

    final rows = await _database.select(_database.kvRows).get();

    for (final row in rows) {
      try {
        _cache[row.key] = jsonDecode(row.jsonValue);
      } catch (_) {
        // Ignore invalid persisted JSON rather than preventing the entire
        // key-value store from loading.
        appLog(
          'Skipped malformed row "${row.key}"',
          name: 'Storage',
          level: LogLevel.warning,
        );
      }
    }

    _loaded = true;
  }

  /// Waits for every queued write to reach SQLite.
  Future<void> flush() => _writeQueue;

  /// Closes the underlying database.
  Future<void> close() => _database.close();

  @override
  dynamic read(String key) => _cache[key];

  @override
  Future<void> write(String key, dynamic value) {
    // Update memory first so subsequent reads immediately see the value, even
    // if the disk write is still queued.
    _cache[key] = value;
    return _enqueue(() async {
      final row = KvRowsCompanion.insert(
        key: key,
        jsonValue: jsonEncode(value),
      );
      await _database.into(_database.kvRows).insertOnConflictUpdate(row);
    });
  }

  @override
  Future<void> remove(String key) {
    _cache.remove(key);
    return _enqueue(() async {
      await (_database.delete(
        _database.kvRows,
      )..where((table) => table.key.equals(key))).go();
    });
  }

  @override
  Iterable<String> getKeys() => _cache.keys;

  Future<void> _enqueue(Future<void> Function() operation) {
    return _writeQueue = _writeQueue.then((_) => operation()).catchError((
      Object error,
    ) {
      appLog('Write failed: $error', name: 'Storage', level: LogLevel.error);
    });
  }
}

/// In-memory [KeyValueStore] for tests and for running before the database is
/// ready.
class MemoryKeyValueStore implements KeyValueStore {
  final Map<String, dynamic> _data = {};

  @override
  dynamic read(String key) => _data[key];

  @override
  Future<void> write(String key, dynamic value) async {
    _data[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }

  @override
  Iterable<String> getKeys() => _data.keys;
}

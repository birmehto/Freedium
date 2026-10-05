import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/storage/app_database.dart';

/// Exercises the v2 -> v3 upgrade against a database that actually looks like
/// an older install, rather than only checking that the current schema builds.
///
/// A migration is the one piece of this app that only ever runs on someone
/// else's device, so it is verified here on a real file: the table has to be
/// present before the upgrade and gone after it, and the data the user cares
/// about has to survive both.
void main() {
  late Directory dir;
  late QueryExecutor executor;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('freedium-migration');
    executor = NativeDatabase(File('${dir.path}/freedium.sqlite'));
    // Raw SQL below stands in for an older version of the app, so the executor
    // is driven directly rather than through a Drift database.
  });

  tearDown(() async {
    await executor.close();
    dir.deleteSync(recursive: true);
  });

  /// Tables actually present, rather than the ones the schema claims.
  Future<List<String>> tableNames() async {
    final rows = await executor.runSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
      [],
    );
    return rows.map((row) => row['name'] as String).toList();
  }

  Future<void> createV2Schema() async {
    // Written out rather than generated, so the test keeps describing the
    // version it claims to. If the table this drops ever comes back, these
    // definitions should stay untouched.
    await executor.runCustom(
      'CREATE TABLE IF NOT EXISTS kv_rows ('
      'key TEXT NOT NULL PRIMARY KEY, '
      'json_value TEXT NOT NULL)',
    );
    await executor.runCustom(
      'CREATE TABLE IF NOT EXISTS cached_articles ('
      'url TEXT NOT NULL PRIMARY KEY, '
      'html TEXT NOT NULL, '
      'title TEXT NOT NULL DEFAULT \'\', '
      'author TEXT NULL, '
      'publication TEXT NULL, '
      'domain TEXT NULL, '
      'word_count INTEGER NOT NULL DEFAULT 0, '
      'saved_at INTEGER NOT NULL)',
    );
    await executor.runCustom(
      'CREATE TABLE IF NOT EXISTS reading_progress_rows ('
      'url TEXT NOT NULL PRIMARY KEY, '
      'ratio REAL NOT NULL DEFAULT 0, '
      'offset REAL NOT NULL DEFAULT 0, '
      'started_at INTEGER NOT NULL, '
      'updated_at INTEGER NOT NULL)',
    );
    await executor.runCustom('PRAGMA user_version = 2');
  }

  test('the progress table is dropped on upgrade and the rest survives', () async {
    await createV2Schema();

    // Rows the reader would miss if the migration were destructive in the wrong
    // place: a favorite and a cached article.
    await executor.runCustom(
      "INSERT INTO kv_rows (key, json_value) VALUES ('favorite:a', 'true')",
    );
    await executor.runCustom(
      'INSERT INTO cached_articles '
      '(url, html, title, author, word_count, saved_at) VALUES '
      "('https://medium.com/a', '<p>body</p>', 'A', 'Ada', 400, 1700000000000)",
    );
    await executor.runCustom(
      'INSERT INTO reading_progress_rows '
      '(url, ratio, offset, started_at, updated_at) VALUES '
      "('https://medium.com/a', 0.5, 900, 1700000000000, 1700000000000)",
    );

    expect(await tableNames(), contains('reading_progress_rows'));

    final database = AppDatabase.forTesting(executor);
    addTearDown(database.close);

    // Opening runs the migration: `beforeOpen` applies `onUpgrade`.
    await database.customSelect('SELECT 1').get();

    final tables = await tableNames();
    expect(
      tables,
      isNot(contains('reading_progress_rows')),
      reason: 'the rows only existed to feed a removed feature',
    );
    expect(tables, contains('kv_rows'));
    expect(tables, contains('cached_articles'));

    final favorites = await database
        .customSelect("SELECT json_value FROM kv_rows WHERE key = 'favorite:a'")
        .get();
    expect(favorites.single.data['json_value'], 'true');

    final cached = await database
        .customSelect('SELECT title FROM cached_articles')
        .get();
    expect(cached.single.data['title'], 'A');
  });

  test('a fresh install has no progress table at all', () async {
    final database = AppDatabase.forTesting(executor);
    addTearDown(database.close);

    await database.customSelect('SELECT 1').get();

    expect(await tableNames(), isNot(contains('reading_progress_rows')));
  });

  test('the schema version the app reports matches the one it migrates', () {
    // If the table is ever reintroduced and `schemaVersion` is left at 3, the
    // next migration has to go to 4 for installs that already ran this one.
    final database = AppDatabase.forTesting(executor);
    addTearDown(database.close);

    expect(database.schemaVersion, 3);
  });
}

import 'package:drift/drift.dart'
    show
        BooleanExpressionOperators,
        ComparableExpr,
        CustomExpression,
        OrderingMode,
        OrderingTerm,
        Value;

import '../../features/article/models/reading_progress.dart';
import '../utils/app_log.dart';
import 'app_database.dart';

/// How far the reader has got through every article it has opened.
///
/// A table of tiny rows rather than a key-value blob, because "Continue
/// reading" is a query — the most recently touched, unfinished articles in
/// order — and answering it from JSON would mean reading and sorting the whole
/// history on every visit to the library.
class ReadingProgressStore {
  ReadingProgressStore(this._database);

  /// How many articles the library offers to continue, at most.
  static const int continueReadingLimit = 5;

  final AppDatabase _database;

  /// The stored position for [url], or `null` when the article was never read.
  Future<ReadingProgress?> progressFor(String url) async {
    final key = url.trim();
    if (key.isEmpty) return null;

    final row = await (_database.select(
      _database.readingProgressRows,
    )..where((table) => table.url.equals(key))).getSingleOrNull();

    return row == null ? null : _toProgress(row);
  }

  /// Records how far the reader has got.
  ///
  /// The first write for an article stamps the start time, later ones keep it,
  /// so "started reading" survives every subsequent save.
  Future<void> save(
    String url, {
    required double ratio,
    double offset = 0,
  }) async {
    final key = url.trim();
    if (key.isEmpty) return;

    final position = ratio.clamp(0.0, 1.0);
    final now = DateTime.now();

    try {
      final existing = await (_database.select(
        _database.readingProgressRows,
      )..where((table) => table.url.equals(key))).getSingleOrNull();

      await _database
          .into(_database.readingProgressRows)
          .insertOnConflictUpdate(
            ReadingProgressRowsCompanion.insert(
              url: key,
              ratio: Value(position),
              offset: Value(offset),
              startedAt: existing?.startedAt ?? now,
              updatedAt: now,
            ),
          );
    } catch (error) {
      appLog(
        'Could not save progress for $key: $error',
        name: 'Progress',
        level: LogLevel.error,
      );
    }
  }

  /// The unfinished articles the reader was last in, most recent first.
  Future<List<ReadingProgress>> continueReading({
    int limit = continueReadingLimit,
  }) async {
    try {
      // The "still in progress" range is part of the query rather than a filter
      // applied to whatever came back: a reader who finishes a few dozen
      // articles after starting one would otherwise push that one out of the
      // result window entirely and the library would look empty.
      final rows =
          await (_database.select(_database.readingProgressRows)
                ..where(
                  (table) =>
                      table.ratio.isBiggerThanValue(
                        ReadingProgress.kStartedThreshold,
                      ) &
                      table.ratio.isSmallerThanValue(
                        ReadingProgress.kFinishedThreshold,
                      ),
                )
                ..orderBy([
                  (table) => OrderingTerm.desc(table.updatedAt),
                  // Two writes can land in the same millisecond, and "most recently
                  // read" then has to mean something: the later insert wins.
                  (table) => OrderingTerm(
                    expression: const CustomExpression<int>('rowid'),
                    mode: OrderingMode.desc,
                  ),
                ])
                ..limit(limit))
              .get();

      return rows.map(_toProgress).toList();
    } catch (error) {
      appLog(
        'Could not read reading history: $error',
        name: 'Progress',
        level: LogLevel.error,
      );
      return const [];
    }
  }

  /// Forgets [url], e.g. when the reader clears its history.
  Future<void> remove(String url) async {
    final key = url.trim();
    if (key.isEmpty) return;

    await (_database.delete(
      _database.readingProgressRows,
    )..where((table) => table.url.equals(key))).go();
  }

  /// Forgets every finished article, keeping the ones still in progress.
  Future<void> clearFinished() async {
    final rows = await _database.select(_database.readingProgressRows).get();

    for (final row in rows) {
      if (row.ratio >= ReadingProgress.kFinishedThreshold) {
        await (_database.delete(
          _database.readingProgressRows,
        )..where((table) => table.url.equals(row.url))).go();
      }
    }
  }

  ReadingProgress _toProgress(ReadingProgressRow row) {
    return ReadingProgress(
      url: row.url,
      ratio: row.ratio,
      offset: row.offset,
      startedAt: row.startedAt,
      updatedAt: row.updatedAt,
    );
  }
}

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

/// A rendered copy of an article, kept so it can be read without a network.
///
/// Deliberately not stored in [KvRows]: article bodies are orders of magnitude
/// larger than preferences, and the key-value store loads every row into memory
/// on startup. Keeping them in their own table means the reader fetches one
/// body when it needs one.
class CachedArticles extends Table {
  /// Canonical URL of the article, from `ArticleUrl.canonicalize`.
  TextColumn get url => text().withLength(min: 1, max: 2048)();

  /// The article's own markup, cleaned of scripts and styles.
  TextColumn get html => text()();

  /// Title, author and publication are denormalized onto the cache so a saved
  /// article can be listed without joining the metadata cache in memory.
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get author => text().nullable()();
  TextColumn get publication => text().nullable()();
  TextColumn get domain => text().nullable()();

  IntColumn get wordCount => integer().withDefault(const Constant(0))();

  /// When this copy was written, which is also the eviction order.
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {url};
}

/// How far the reader has got through an article.
///
/// Progress outlives the cached body: a finished article drops out of the cache
/// but stays here so "Continue reading" can tell it apart from an article that
/// was never opened.
class ReadingProgressRows extends Table {
  TextColumn get url => text().withLength(min: 1, max: 2048)();

  /// Fraction of the scrollable distance covered, in `0..1`.
  RealColumn get ratio => real().withDefault(const Constant(0))();

  /// Absolute scroll offset in CSS pixels, used to restore the exact position
  /// when the article's height has not changed since it was last read.
  RealColumn get offset => real().withDefault(const Constant(0))();

  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {url};
}

/// The app's SQLite database, managed by Drift.
///
/// Preferences and library data both flow through the [KvRows] table via a
/// [DriftKeyValueStore] so reads stay synchronous while every write is
/// persisted asynchronously through Drift/SQLite. Article bodies and reading
/// progress live in their own tables because they are read one row at a time.
@DriftDatabase(tables: [KvRows, CachedArticles, ReadingProgressRows])
class AppDatabase extends _$AppDatabase {
  /// Opens the on-device database (Android/iOS/desktop).
  AppDatabase.open() : super(driftDatabase(name: 'freedium'));

  /// For the supplied executor (tests use an in-memory database).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    // Additive only: every version so far has just added tables, and
    // `createAll` skips the ones that already exist, so a v1 install keeps its
    // preferences, favorites and metadata cache untouched.
    onUpgrade: (m, from, to) => m.createAll(),
  );
}

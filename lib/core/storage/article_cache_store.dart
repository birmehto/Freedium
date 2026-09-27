import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:get/get.dart' hide Value;

import '../../features/article/models/article_meta.dart';
import '../utils/app_log.dart';
import 'app_database.dart';

/// On-device copies of rendered articles, so a favorite stays readable when the
/// network or every mirror is unavailable.
///
/// An article is only here because the reader favorited it, so the table is the
/// reader's own shelf rather than a side effect of reading: the reader drops a
/// copy with [remove], and the ceiling below is the only thing that ever takes
/// one away on its own.
///
/// Bodies live in their own table instead of the key-value store because they
/// are large and only ever needed one at a time: [read] pulls a single row when
/// the reader actually needs it, and nothing is held in memory while the app is
/// idle.
class ArticleCacheStore {
  ArticleCacheStore(this._database);

  /// Soft ceiling on the total size of the stored articles. The least recently
  /// saved are evicted past it, so storage cannot grow without bound on a device
  /// that keeps a lot of long-form writing.
  static const int maxCacheBytes = 24 * 1024 * 1024;

  /// An article whose markup exceeds this is not cached at all.
  ///
  /// A single pathological page (an infinite feed, a generated table) would
  /// otherwise evict everything else and still be useless offline.
  static const int maxArticleBytes = 2 * 1024 * 1024;

  /// How many candidates one eviction pass looks at.
  ///
  /// Bounded so a badly over-budget cache does not turn a single save into a
  /// scan of the whole table; the next save carries on from there.
  static const int _evictionBatchSize = 8;

  final AppDatabase _database;

  final cachedCount = 0.obs;
  final cachedBytes = 0.obs;

  /// The saved copy of [url], or `null` when nothing is cached for it.
  Future<CachedArticle?> read(String url) async {
    final key = url.trim();
    if (key.isEmpty) return null;

    return (_database.select(
      _database.cachedArticles,
    )..where((table) => table.url.equals(key))).getSingleOrNull();
  }

  /// Whether a saved copy of [url] exists, without reading its body.
  Future<bool> contains(String url) async {
    final key = url.trim();
    if (key.isEmpty) return false;

    final row =
        await (_database.selectOnly(_database.cachedArticles)
              ..addColumns([_database.cachedArticles.url])
              ..where(_database.cachedArticles.url.equals(key))
              ..limit(1))
            .getSingleOrNull();

    return row != null;
  }

  /// Keeps (or refreshes) the copy of one article.
  ///
  /// Returns false when the article was too large to keep, or when the write
  /// failed, so the caller can tell "saved" from "silently skipped". Failures
  /// are logged rather than thrown: a reader must not fail because a save did.
  ///
  /// [keep] lists URLs that eviction must never touch — the favorited articles.
  /// A copy with no favorite behind it is what the ceiling is allowed to reclaim.
  Future<bool> save({
    required String url,
    required String html,
    String title = '',
    String? author,
    String? publication,
    String? domain,
    int wordCount = 0,
    Iterable<String> keep = const [],
  }) async {
    final key = url.trim();
    if (key.isEmpty || html.trim().isEmpty) return false;

    // Measured in bytes, because that is what the ceiling below is expressed
    // in: a multi-megabyte markup is far more UTF-8 than characters.
    final size = _sizeOf(html);

    if (size > maxArticleBytes) {
      appLog(
        'Skipped caching $key: $size bytes is over the per-article cap',
        name: 'Cache',
        level: LogLevel.warning,
      );
      return false;
    }

    try {
      final previous = await read(key);

      await _database
          .into(_database.cachedArticles)
          .insertOnConflictUpdate(
            CachedArticlesCompanion.insert(
              url: key,
              html: html,
              title: Value(title),
              author: Value(author),
              publication: Value(publication),
              domain: Value(domain),
              wordCount: Value(wordCount),
              savedAt: DateTime.now(),
            ),
          );

      // The new body replaced whatever was there, so only the difference counts
      // towards the total.
      cachedBytes.value +=
          size - (previous == null ? 0 : _sizeOf(previous.html));
      if (previous == null) cachedCount.value += 1;

      await _evictOverflow(keep, protecting: key);
      return true;
    } catch (error) {
      appLog(
        'Could not cache $key: $error',
        name: 'Cache',
        level: LogLevel.error,
      );
      return false;
    }
  }

  /// Caches an article alongside the metadata the reader already extracted.
  Future<bool> saveWithMeta({
    required String url,
    required String html,
    required ArticleMeta meta,
    String? domain,
    Iterable<String> keep = const [],
  }) {
    return save(
      url: url,
      html: html,
      title: meta.title,
      author: meta.author,
      publication: meta.publication,
      domain: domain,
      wordCount: meta.wordCount,
      keep: keep,
    );
  }

  /// Drops the copy of one article, e.g. when the user removes a favorite.
  Future<void> remove(String url) async {
    final key = url.trim();
    if (key.isEmpty) return;

    final removed = await read(key);
    if (removed == null) return;

    await (_database.delete(
      _database.cachedArticles,
    )..where((table) => table.url.equals(key))).go();

    _forget(_sizeOf(removed.html));
  }

  /// Recounts the cache, for a store that has just been opened.
  Future<void> refreshTotals() async {
    try {
      // Raw SQL because drift has no aggregate over a text column's byte
      // length, and counting in Dart would mean reading every cached body into
      // memory. CAST to BLOB is what makes LENGTH count UTF-8 bytes rather than
      // characters, which is the unit the ceiling is expressed in.
      final row = await _database
          .customSelect(
            'SELECT COUNT(*) AS item_count, '
            'COALESCE(SUM(LENGTH(CAST(cached_articles.html AS BLOB))), 0) '
            'AS byte_count FROM cached_articles',
            readsFrom: {_database.cachedArticles},
          )
          .getSingle();

      cachedCount.value = row.read<int>('item_count');
      cachedBytes.value = row.read<int>('byte_count');
    } catch (error) {
      appLog(
        'Could not read cache totals: $error',
        name: 'Cache',
        level: LogLevel.warning,
      );
    }
  }

  /// Removes the least recently saved articles until the store fits again.
  ///
  /// [protecting] is the article just written: a page that only fits because
  /// everything else went would otherwise evict itself on the way in, and the
  /// reader would get no offline copy at all.
  Future<void> _evictOverflow(
    Iterable<String> keep, {
    required String protecting,
  }) async {
    if (cachedBytes.value <= maxCacheBytes) return;

    final pinned = {for (final url in keep) url.trim()}..remove('');
    pinned.add(protecting.trim());

    // Pinned articles are excluded by the query rather than skipped inside the
    // loop: a batch spent on rows that cannot be evicted frees nothing, so a
    // store full of favorites could never get back under the ceiling.
    final oldest =
        await (_database.select(_database.cachedArticles)
              ..where((table) => table.url.isNotIn(pinned))
              ..orderBy([(table) => OrderingTerm.asc(table.savedAt)])
              ..limit(_evictionBatchSize))
            .get();

    for (final row in oldest) {
      if (cachedBytes.value <= maxCacheBytes) break;

      await (_database.delete(
        _database.cachedArticles,
      )..where((table) => table.url.equals(row.url))).go();

      _forget(_sizeOf(row.html));
    }

    if (cachedBytes.value > maxCacheBytes) {
      appLog(
        'Cache still over budget after eviction: ${cachedBytes.value} bytes',
        name: 'Cache',
        level: LogLevel.warning,
      );
    }
  }

  /// Size of [html] in bytes, matching what SQLite reports for the column.
  int _sizeOf(String html) => utf8.encode(html).length;

  /// Drops one article's contribution from the running totals.
  void _forget(int bytes) {
    cachedCount.value = math.max(0, cachedCount.value - 1);
    cachedBytes.value = math.max(0, cachedBytes.value - bytes);
  }
}

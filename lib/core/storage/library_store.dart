import 'package:get/get_rx/get_rx.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';

import '../../features/article/models/article_meta.dart';
import '../../features/article/models/reading_progress.dart';
import '../../features/article/models/saved_article.dart';
import '../../features/library/models/history_entry.dart';
import 'key_value_store.dart';

/// Reading data: favorites, history, reading progress, saved articles and
/// local reading statistics.
///
/// Separate from [PreferencesStore] so content data stays isolated from
/// device settings.
class LibraryStore {
  LibraryStore(this._box);

  static const kFavorites = 'favorites_list';
  static const kHistory = 'history_list';
  static const kReadingProgress = 'reading_progress';
  static const kSavedArticles = 'saved_articles';
  static const kReadingStats = 'reading_stats';
  static const kMaxSavedBytes = 64 * 1024 * 1024;

  final KeyValueStore _box;

  /// Emits on every favorites mutation so list views can rebuild reactively.
  final RxInt favoritesRevision = 0.obs;

  /// Emits on any history / saved-article / progress mutation.
  final RxInt libraryRevision = 0.obs;

  // ─────────────────────────────── favorites ───────────────────────────

  List<Map<String, dynamic>> get favorites {
    final raw = _box.read(kFavorites);
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  bool isFavorite(String url) {
    final target = url.trim();
    return favorites.any((f) => (f['url'] as String? ?? '').trim() == target);
  }

  Future<void> addToFavorites(Map<String, dynamic> item) async {
    final existing = List<Map<String, dynamic>>.from(favorites);
    existing.removeWhere(
      (f) => (f['url'] as String? ?? '').trim() == (item['url'] ?? '').trim(),
    );
    existing.insert(0, item);
    await _box.write(kFavorites, existing);
    favoritesRevision.value++;
  }

  Future<void> removeFromFavorites(String url) async {
    final existing = favorites
        .where((f) => (f['url'] as String? ?? '').trim() != url.trim())
        .toList();
    await _box.write(kFavorites, existing);
    favoritesRevision.value++;
  }

  Future<void> clearFavorites() async {
    await _box.write(kFavorites, <Map<String, dynamic>>[]);
    favoritesRevision.value++;
    libraryRevision.value++;
  }

  // ─────────────────────────────── history ─────────────────────────────

  List<HistoryEntry> get history {
    final raw = _box.read(kHistory);
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => HistoryEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  void recordHistory(HistoryEntry entry) {
    final current = history;
    current.removeWhere((h) => h.url == entry.url);
    current.insert(0, entry);
    _box.write(kHistory, current.map((e) => e.toJson()).toList());
    libraryRevision.value++;
  }

  void updateHistory(HistoryEntry entry) {
    final current = history;
    final index = current.indexWhere((h) => h.url == entry.url);
    if (index == -1) {
      recordHistory(entry);
      return;
    }
    current[index] = entry;
    _box.write(kHistory, current.map((e) => e.toJson()).toList());
    libraryRevision.value++;
  }

  void removeHistory(String url) {
    _box.write(
      kHistory,
      history.where((h) => h.url != url).map((e) => e.toJson()).toList(),
    );
    libraryRevision.value++;
  }

  void clearHistory() {
    _box.write(kHistory, <Map<String, dynamic>>[]);
    libraryRevision.value++;
  }

  HistoryEntry? historyFor(String url) {
    for (final entry in history) {
      if (entry.url == url) return entry;
    }
    return null;
  }

  // ─────────────────────────── reading progress ────────────────────────

  Map<String, dynamic> _progressMap() {
    final raw = _box.read(kReadingProgress);
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  ReadingProgress getReadingProgress(String url) {
    final map = _progressMap();
    final entry = map[url];
    if (entry is Map) {
      return ReadingProgress.fromJson(Map<String, dynamic>.from(entry));
    }
    if (entry is num) {
      return ReadingProgress(
        progress: entry.toDouble(),
        lastReadAt: DateTime.now(),
      );
    }
    return const ReadingProgress();
  }

  void saveReadingProgress(String url, ReadingProgress progress) {
    final map = _progressMap();
    map[url] = progress.toJson();
    _box.write(kReadingProgress, map);
    libraryRevision.value++;
  }

  void clearReadingProgress(String url) {
    final map = _progressMap();
    map.remove(url);
    _box.write(kReadingProgress, map);
    libraryRevision.value++;
  }

  // ─────────────────────────── saved articles ──────────────────────────

  List<SavedArticle> get savedArticles {
    final raw = _box.read(kSavedArticles);
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => SavedArticle.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  int get savedBytes =>
      savedArticles.fold(0, (sum, article) => sum + article.approximateBytes);

  bool isSaved(String url) =>
      savedArticles.any((a) => a.url.trim() == url.trim());

  SavedArticle? savedArticleFor(String url) {
    for (final article in savedArticles) {
      if (article.url.trim() == url.trim()) return article;
    }
    return null;
  }

  /// Saves an article off-line. Returns true when it was kept, false when the
  /// cache budget was exceeded (oldest articles are evicted first).
  bool saveArticle(SavedArticle article) {
    final articles = savedArticles;
    articles.removeWhere((a) => a.url.trim() == article.url.trim());
    articles.insert(0, article);

    var bytes = articles.fold(0, (sum, a) => sum + a.approximateBytes);
    while (bytes > kMaxSavedBytes && articles.length > 1) {
      bytes -= articles.last.approximateBytes;
      articles.removeLast();
    }
    if (bytes > kMaxSavedBytes) return false;
    _box.write(kSavedArticles, articles.map((a) => a.toJson()).toList());
    libraryRevision.value++;
    return true;
  }

  void removeSavedArticle(String url) {
    _box.write(
      kSavedArticles,
      savedArticles
          .where((a) => a.url.trim() != url.trim())
          .map((a) => a.toJson())
          .toList(),
    );
    libraryRevision.value++;
  }

  void clearSavedArticles() {
    _box.write(kSavedArticles, <Map<String, dynamic>>[]);
    libraryRevision.value++;
  }

  // ─────────────────────────── reading statistics ──────────────────────

  Map<String, dynamic> get readingStats {
    final raw = _box.read(kReadingStats);
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {'openCount': 0, 'readingMinutes': 0, 'completedCount': 0};
  }

  /// Locally-stored, never sent anywhere. Reading minutes are the product of
  /// time spent in the article reader view.
  void recordReadSession({
    int openCountDelta = 0,
    int readingMinutes = 0,
    bool completed = false,
  }) {
    final stats = readingStats;
    stats['openCount'] = (stats['openCount'] as num? ?? 0) + openCountDelta;
    if (completed) {
      stats['completedCount'] = (stats['completedCount'] as num? ?? 0) + 1;
    }
    if (readingMinutes > 0) {
      stats['readingMinutes'] =
          (stats['readingMinutes'] as num? ?? 0) + readingMinutes;
    }
    _box.write(kReadingStats, stats);
  }

  // ─────────────────────────────── metadata ────────────────────────────

  Map<String, ArticleMeta> get cachedMeta {
    final raw = _box.read('cached_meta');
    if (raw is Map) {
      return Map<String, dynamic>.from(raw).map(
        (key, value) => MapEntry(
          key,
          ArticleMeta.fromJson(Map<String, dynamic>.from(value as Map)),
        ),
      );
    }
    return {};
  }

  void cacheMeta(String url, ArticleMeta meta) {
    final current = cachedMeta;
    current[url] = meta;
    _box.write('cached_meta', current.map((k, v) => MapEntry(k, v.toJson())));
  }
}

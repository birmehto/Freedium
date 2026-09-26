import 'package:get/get.dart';

import '../../features/article/models/article_meta.dart';
import '../../features/favorites/models/favorite_article.dart';
import 'key_value_store.dart';

/// Reading data owned by the user: the favorites list and cached article
/// metadata.
///
/// The store is the single source of truth for both. Views read the reactive
/// collections directly instead of keeping their own copies in sync.
class LibraryStore {
  LibraryStore(this._store);

  /// Keys are kept stable so an existing saved library survives the refactor.
  static const String favoritesKey = 'favorites_list';
  static const String metaKey = 'cached_meta';

  /// How many articles the metadata blob keeps.
  ///
  /// The blob is one row, so every article opened rewrites all of it. Capping
  /// the number of entries (least recently written first) keeps that rewrite
  /// bounded on a device that reads a lot, and an article whose metadata is
  /// dropped simply falls back to its favorite entry until it is read again.
  static const int maxMetaEntries = 500;

  final KeyValueStore _store;

  final RxList<FavoriteArticle> _favorites = <FavoriteArticle>[].obs;

  bool _loaded = false;

  /// Favorites, most recently added first.
  ///
  /// Exposed as the reactive list itself so views and tests observe mutations
  /// directly instead of polling a copy.
  RxList<FavoriteArticle> get favorites {
    _ensureLoaded();
    return _favorites;
  }

  bool isFavorite(String url) {
    final target = url.trim();
    return favorites.any((item) => item.url.trim() == target);
  }

  /// Adds [article] to favorites, replacing any earlier entry for the same URL
  /// so a URL can never appear twice.
  Future<void> addToFavorites(FavoriteArticle article) {
    final target = article.url.trim();

    return _saveFavorites([
      article,
      ...favorites.where((item) => item.url.trim() != target),
    ]);
  }

  Future<void> removeFromFavorites(String url) {
    final target = url.trim();
    return _saveFavorites(
      favorites.where((item) => item.url.trim() != target).toList(),
    );
  }

  /// Adds [article] when absent, removes it when present, and returns the
  /// resulting state so the caller does not have to guess.
  Future<bool> toggleFavorite(FavoriteArticle article) async {
    if (isFavorite(article.url)) {
      await removeFromFavorites(article.url);
      return false;
    }
    await addToFavorites(article);
    return true;
  }

  /// Metadata cached for [url], or `null` when nothing is cached.
  ArticleMeta? metaFor(String url) {
    final raw = _rawMeta()[url.trim()];
    if (raw is! Map) return null;
    return ArticleMeta.fromJson(Map<String, dynamic>.from(raw));
  }

  /// Caches [meta] for [url]. Only that one entry is re-encoded, so a long
  /// reading history does not cost a full read/parse/rewrite per article.
  Future<void> cacheMeta(String url, ArticleMeta meta) async {
    final key = url.trim();
    if (key.isEmpty) return;

    final current = Map<String, dynamic>.from(_rawMeta());

    // Re-inserted rather than overwritten so the map's insertion order really
    // is oldest-written first, which is what the cap below evicts from.
    current
      ..remove(key)
      ..[key] = meta.toJson();

    while (current.length > maxMetaEntries) {
      current.remove(current.keys.first);
    }

    await _store.write(metaKey, current);
  }

  /// Forgets the metadata cached for [url], e.g. when the user removes it from
  /// the library.
  Future<void> removeMeta(String url) async {
    final key = url.trim();
    if (key.isEmpty) return;

    final current = Map<String, dynamic>.from(_rawMeta());
    if (current.remove(key) == null) return;

    await _store.write(metaKey, current);
  }

  Future<void> _saveFavorites(List<FavoriteArticle> next) async {
    // Update the observable list first so the UI reacts immediately; the
    // persistence layer logs any failure instead of breaking the interaction.
    _favorites.assignAll(next);
    await _store.write(favoritesKey, [for (final item in next) item.toJson()]);
  }

  Map<String, dynamic> _rawMeta() {
    _ensureLoaded();
    final raw = _store.read(metaKey);
    return raw is Map ? Map<String, dynamic>.from(raw) : {};
  }

  /// Hydrates from the (already in-memory) key-value store on first access.
  void _ensureLoaded() {
    if (_loaded) return;
    _loaded = true;

    final raw = _store.read(favoritesKey);
    if (raw is! List) return;

    final articles = <FavoriteArticle>[];
    for (final entry in raw) {
      if (entry is Map) {
        articles.add(
          FavoriteArticle.fromJson(Map<String, dynamic>.from(entry)),
        );
      }
    }

    _favorites.assignAll(articles);
  }
}

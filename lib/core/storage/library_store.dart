import '../../features/article/models/article_meta.dart';
import '../../features/favorites/models/favorite_article.dart';
import 'key_value_store.dart';

/// Reading data owned by the user: the favorites list and cached article
/// metadata. The store is the single source of truth for both.
class LibraryStore {
  LibraryStore(this._store);

  static const String favoritesKey = 'favorites_list';
  static const String metaKey = 'cached_meta';

  /// One row holds all metadata, so it is capped (oldest first) to keep the
  /// rewrite bounded on a device that reads a lot.
  static const int maxMetaEntries = 500;

  final KeyValueStore _store;

  List<FavoriteArticle> _favorites = const [];
  bool _loaded = false;

  /// Favorites, most recently added first.
  List<FavoriteArticle> get favorites {
    _ensureLoaded();
    return _favorites;
  }

  bool isFavorite(String url) {
    final target = url.trim();
    return favorites.any((item) => item.url.trim() == target);
  }

  /// Adds [article], replacing any earlier entry for the same URL.
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

  /// Adds when absent, removes when present, and returns the resulting state.
  Future<bool> toggleFavorite(FavoriteArticle article) async {
    if (isFavorite(article.url)) {
      await removeFromFavorites(article.url);
      return false;
    }
    await addToFavorites(article);
    return true;
  }

  ArticleMeta? metaFor(String url) {
    final raw = _rawMeta()[url.trim()];
    if (raw is! Map) return null;
    return ArticleMeta.fromJson(Map<String, dynamic>.from(raw));
  }

  /// Caches metadata for [url], re-inserting so insertion order stays
  /// oldest-written-first for the cap below.
  Future<void> cacheMeta(String url, ArticleMeta meta) async {
    final key = url.trim();
    if (key.isEmpty) return;

    final current = Map<String, dynamic>.from(_rawMeta())
      ..remove(key)
      ..[key] = meta.toJson();

    while (current.length > maxMetaEntries) {
      current.remove(current.keys.first);
    }

    await _store.write(metaKey, current);
  }

  Future<void> removeMeta(String url) async {
    final key = url.trim();
    if (key.isEmpty) return;

    final current = Map<String, dynamic>.from(_rawMeta());
    if (current.remove(key) == null) return;

    await _store.write(metaKey, current);
  }

  Future<void> _saveFavorites(List<FavoriteArticle> next) async {
    _favorites = List.unmodifiable(next);
    await _store.write(favoritesKey, [for (final item in next) item.toJson()]);
  }

  Map<String, dynamic> _rawMeta() {
    _ensureLoaded();
    final raw = _store.read(metaKey);
    return raw is Map ? Map<String, dynamic>.from(raw) : {};
  }

  /// Hydrates from the already in-memory key-value store on first access.
  void _ensureLoaded() {
    if (_loaded) return;
    _loaded = true;

    final raw = _store.read(favoritesKey);
    if (raw is! List) return;

    _favorites = List.unmodifiable(
      raw.whereType<Map>().map(
        (entry) => FavoriteArticle.fromJson(Map<String, dynamic>.from(entry)),
      ),
    );
  }
}

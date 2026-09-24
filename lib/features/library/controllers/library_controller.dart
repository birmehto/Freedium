import 'package:get/get.dart';

import '../../../core/services/storage_service.dart';
import '../../favorites/models/favorite_article.dart';

class LibraryController extends GetxController {
  LibraryController(this._storage);

  final StorageService _storage;

  final searchQuery = ''.obs;
  final recentSearches = <String>[].obs;
  final favorites = <FavoriteArticle>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
    recentSearches.value = _storage.preferences.recentSearches;
    ever(_storage.favoritesRevision, (_) => _scheduleLoadAll());
  }

  void _scheduleLoadAll() {
    Future.microtask(loadAll);
  }

  void loadAll() {
    favorites.value = _storage.library.favorites
        .map((e) => FavoriteArticle.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<FavoriteArticle> get filteredFavorites => _applyQuery(favorites);

  int get visibleCount => filteredFavorites.length;

  List<T> _applyQuery<T>(List<T> items) {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return items;

    String? textFor(T item) {
      if (item is FavoriteArticle) {
        return '${item.title} ${item.author ?? ''} ${item.domain ?? ''}';
      }
      return null;
    }

    final result = [
      for (final item in items)
        if (textFor(item)?.toLowerCase().contains(query) ?? false) item,
    ];
    if (result.isNotEmpty) {
      _storage.preferences.addRecentSearch(searchQuery.value);
      recentSearches.value = _storage.preferences.recentSearches;
    }
    return result;
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
  }

  void onRecentSearchTap(String query) {
    searchQuery.value = query;
  }

  void clearRecentSearches() {
    _storage.preferences.clearRecentSearches();
    recentSearches.value = [];
  }

  Future<void> removeFavorite(String url) async {
    await _storage.library.removeFromFavorites(url);
  }

  Future<void> clearFavorites() async {
    await _storage.library.clearFavorites();
  }
}
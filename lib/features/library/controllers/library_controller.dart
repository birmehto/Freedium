import 'package:get/get.dart';

import '../../../core/services/storage_service.dart';
import '../../article/models/saved_article.dart';
import '../../favorites/models/favorite_article.dart';
import '../models/history_entry.dart';

enum LibrarySection { reading, favorites, saved, history }

class LibraryController extends GetxController {
  LibraryController(this._storage);

  final StorageService _storage;

  final activeSection = LibrarySection.reading.obs;
  final searchQuery = ''.obs;
  final recentSearches = <String>[].obs;
  final favorites = <FavoriteArticle>[].obs;
  final saved = <SavedArticle>[].obs;
  final history = <HistoryEntry>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
    recentSearches.value = _storage.preferences.recentSearches;
    ever(_storage.favoritesRevision, (_) => loadAll());
    ever(_storage.library.libraryRevision, (_) => loadAll());
  }

  void loadAll() {
    favorites.value = _storage.library.favorites
        .map((e) => FavoriteArticle.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    saved.value = _storage.library.savedArticles;
    history.value = _storage.library.history;

    // Keep the continue-reading section in sync with progress stored by the
    // reader while the library stays alive in the background shell.
    final progress = _storage.library.getReadingProgress;
    history.value = history.map((entry) {
      if (entry.progress > 0) return entry;
      return entry.copyWith(progress: progress(entry.url).progress);
    }).toList();
  }

  /// Articles with saved progress that have not been finished yet.
  List<HistoryEntry> get continueReading {
    final result =
        history.where((e) => e.progress > 0.0 && !e.completed).toList()..sort(
          (a, b) => (b.lastReadAt ?? b.openedAt ?? DateTime(0)).compareTo(
            a.lastReadAt ?? a.openedAt ?? DateTime(0),
          ),
        );
    return _applyQuery(result);
  }

  List<FavoriteArticle> get filteredFavorites => _applyQuery(favorites);

  List<SavedArticle> get filteredSaved => _applyQuery(saved);

  List<HistoryEntry> get filteredHistory {
    final filtered = _applyQuery(history)
      ..sort(
        (a, b) => (b.lastReadAt ?? b.openedAt ?? DateTime(0)).compareTo(
          a.lastReadAt ?? a.openedAt ?? DateTime(0),
        ),
      );
    return filtered;
  }

  int get visibleCount {
    switch (activeSection.value) {
      case LibrarySection.reading:
        return continueReading.length;
      case LibrarySection.favorites:
        return filteredFavorites.length;
      case LibrarySection.saved:
        return filteredSaved.length;
      case LibrarySection.history:
        return filteredHistory.length;
    }
  }

  List<T> _applyQuery<T>(List<T> items) {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return items;

    String? textFor(T item) {
      if (item is HistoryEntry) {
        return '${item.title} ${item.author ?? ''} ${item.publication ?? ''} ${item.url}';
      }
      if (item is FavoriteArticle) {
        return '${item.title} ${item.author ?? ''} ${item.domain ?? ''}';
      }
      if (item is SavedArticle) {
        return '${item.title} ${item.author ?? ''} ${item.publication ?? ''}';
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

  void onSectionChanged(LibrarySection section) {
    activeSection.value = section;
  }

  Future<void> removeFavorite(String url) async {
    await _storage.library.removeFromFavorites(url);
  }

  void removeSaved(String url) {
    _storage.library.removeSavedArticle(url);
  }

  void removeHistory(String url) {
    _storage.library.removeHistory(url);
    _storage.library.clearReadingProgress(url);
  }

  void clearHistory() {
    _storage.library.clearHistory();
  }

  Future<void> clearFavorites() async {
    await _storage.library.clearFavorites();
  }
}

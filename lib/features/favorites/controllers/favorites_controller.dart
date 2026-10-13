import 'package:get/get.dart';

import '../../../core/services/storage_service.dart';
import '../models/favorite_article.dart';

class FavoritesController extends GetxController {
  FavoritesController(this._storage);

  final StorageService _storage;

  final searchQuery = ''.obs;

  /// Bumped when a swipe is cancelled, so the dismissible list rebuilds its
  /// rows and puts the article back where it was.
  final dismissEpoch = 0.obs;

  /// Articles with a removal in flight, so a double tap cannot start a second
  /// cascade for the same URL.
  final Set<String> _removing = <String>{};

  /// URLs whose remove-confirmation dialog is open.
  ///
  /// A full swipe reports *both* the auto-run of the primary delete action and
  /// the list's own `onDismiss`, so without this guard the "keep?" dialog would
  /// be pushed twice and stacked.
  final Set<String> _confirmingRemoval = <String>{};

  /// Claims the remove-confirmation dialog for [url]. Returns false when one is
  /// already open, so the same swipe cannot open a second.
  bool startRemovalConfirm(String url) => _confirmingRemoval.add(url.trim());

  void endRemovalConfirm(String url) => _confirmingRemoval.remove(url.trim());

  /// Favorites are read straight from the library store rather than mirrored
  /// into a second list, so the two can never drift apart.
  List<FavoriteArticle> get favorites => _storage.library.favorites;

  /// The search text with surrounding whitespace removed, which is what both
  /// the filter and the "is the user searching" checks agree on.
  String get trimmedQuery => searchQuery.value.trim();

  List<FavoriteArticle> get filteredFavorites {
    final query = trimmedQuery.toLowerCase();
    if (query.isEmpty) return favorites;

    bool matches(FavoriteArticle item, String? value) =>
        value != null && value.toLowerCase().contains(query);

    return favorites
        .where(
          (item) =>
              item.title.toLowerCase().contains(query) ||
              matches(item, item.author) ||
              matches(item, item.domain),
        )
        .toList();
  }

  /// Removes an article from the library and everything stored about it.
  ///
  /// The saved copy, its cached metadata and its cached body all describe the
  /// same article, so deleting it means all three: an article the user threw
  /// away should not keep taking up space or keep showing a title in the library
  /// count.
  Future<void> removeFavorite(String url) async {
    final key = url.trim();
    if (key.isEmpty || !_removing.add(key)) return;

    try {
      await _storage.library.removeFromFavorites(key);
      await _storage.library.removeMeta(key);
      await _storage.cache.remove(key);
    } finally {
      _removing.remove(key);
    }
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
  }
}

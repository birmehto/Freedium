import 'package:get/get.dart';

import '../../../core/services/storage_service.dart';
import '../models/favorite_article.dart';

class FavoritesController extends GetxController {
  FavoritesController(this._storage);

  final StorageService _storage;

  final searchQuery = ''.obs;

  /// Favorites are read straight from the library store rather than mirrored
  /// into a second list, so the two can never drift apart.
  List<FavoriteArticle> get favorites => _storage.library.favorites;

  List<FavoriteArticle> get filteredFavorites {
    final query = searchQuery.value.trim().toLowerCase();
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

  Future<void> removeFavorite(String url) =>
      _storage.library.removeFromFavorites(url);

  void onSearchChanged(String query) {
    searchQuery.value = query;
  }
}

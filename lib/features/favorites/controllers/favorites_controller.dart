import 'package:get/get.dart';

import '../../../core/services/storage_service.dart';
import '../models/favorite_article.dart';

class FavoritesController extends GetxController {
  FavoritesController(this._storage);
  final StorageService _storage;

  final favorites = <FavoriteArticle>[].obs;
  final searchQuery = ''.obs;

  List<FavoriteArticle> get filteredFavorites => favorites
      .where(
        (item) =>
            item.title.toLowerCase().contains(
              searchQuery.value.toLowerCase(),
            ) ||
            (item.author?.toLowerCase().contains(
                  searchQuery.value.toLowerCase(),
                ) ??
                false) ||
            (item.domain?.toLowerCase().contains(
                  searchQuery.value.toLowerCase(),
                ) ??
                false),
      )
      .toList();

  @override
  void onInit() {
    super.onInit();
    loadFavorites();
    ever(_storage.favoritesRevision, (_) => loadFavorites());
  }

  Future<void> loadFavorites() async {
    favorites.value = _storage.favorites
        .map((e) => FavoriteArticle.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> removeFavorite(String url) async {
    await _storage.removeFromFavorites(url);
    favorites.removeWhere((item) => item.url == url);
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
  }
}

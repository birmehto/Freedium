import 'dart:async';

import 'package:get/get.dart';

import '../../../core/network/article_url.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/app_log.dart';
import '../models/continue_reading_item.dart';
import '../models/favorite_article.dart';

class FavoritesController extends GetxController {
  FavoritesController(this._storage);

  final StorageService _storage;

  final searchQuery = ''.obs;

  /// Articles the reader started and did not finish, most recent first.
  final continueReading = <ContinueReadingItem>[].obs;

  /// Bumped when a swipe is cancelled, so the dismissible list rebuilds its
  /// rows and puts the article back where it was.
  final dismissEpoch = 0.obs;

  /// Articles with a removal in flight, so a double tap cannot start a second
  /// cascade for the same URL.
  final Set<String> _removing = <String>{};

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

  @override
  void onInit() {
    super.onInit();
    unawaited(refreshContinueReading());
  }

  /// Removes an article from the library and everything stored about it.
  ///
  /// The saved copy, its cached metadata and its reading position all describe
  /// the same article, so deleting it means all four: an article the user threw
  /// away should not keep taking up space, keep showing a title in the library
  /// count, or reappear under "Continue reading".
  Future<void> removeFavorite(String url) async {
    final key = url.trim();
    if (key.isEmpty || !_removing.add(key)) return;

    try {
      await _storage.library.removeFromFavorites(key);
      await _storage.library.removeMeta(key);
      await _storage.cache.remove(key);
      await _storage.progress.remove(key);
      await refreshContinueReading();
    } finally {
      _removing.remove(key);
    }
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
  }

  /// Rebuilds the "Continue reading" list from the stored reading positions.
  ///
  /// Kept separate from the favorites list on purpose: an article is
  /// remembered whether or not it was ever saved, and the two lists answer
  /// different questions.
  ///
  /// Overlapping calls share one read, so returning from the reader and
  /// switching tabs at the same time cannot interleave two rebuilds.
  Future<void> refreshContinueReading() {
    return _refreshing ??= _buildContinueReading().whenComplete(
      () => _refreshing = null,
    );
  }

  Future<void>? _refreshing;

  Future<void> _buildContinueReading() async {
    try {
      final progress = await _storage.progress.continueReading();

      continueReading.assignAll([
        for (final entry in progress)
          () {
            final meta = _storage.library.metaFor(entry.url);

            return ContinueReadingItem(
              url: entry.url,
              title: meta?.title ?? '',
              ratio: entry.ratio,
              author: meta?.author,
              domain: ArticleUrl.hostOf(entry.url),
              updatedAt: entry.updatedAt,
            );
          }(),
      ]);
    } catch (error) {
      appLog(
        'Could not build continue reading: $error',
        name: 'Library',
        level: LogLevel.warning,
      );
    }
  }
}

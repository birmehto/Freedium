import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/controllers/app_controllers.dart';
import '../models/favorite_article.dart';

class FavoritesState {
  const FavoritesState({this.searchQuery = '', this.dismissEpoch = 0});

  final String searchQuery;

  /// Bumped when a swipe is cancelled so dismissible rows rebuild in place.
  final int dismissEpoch;

  FavoritesState copyWith({String? searchQuery, int? dismissEpoch}) {
    return FavoritesState(
      searchQuery: searchQuery ?? this.searchQuery,
      dismissEpoch: dismissEpoch ?? this.dismissEpoch,
    );
  }
}

final favoritesControllerProvider =
    NotifierProvider<FavoritesController, FavoritesState>(
      FavoritesController.new,
    );

class FavoritesController extends Notifier<FavoritesState> {
  @override
  FavoritesState build() => const FavoritesState();

  /// URLs with a removal in flight, so a double tap cannot start two cascades.
  final Set<String> _removing = <String>{};

  /// URLs whose remove-confirmation dialog is open. A full swipe reports both
  /// the primary delete action and the list's `onDismiss`; without this guard
  /// the "keep?" dialog would be pushed twice.
  final Set<String> _confirmingRemoval = <String>{};

  bool startRemovalConfirm(String url) => _confirmingRemoval.add(url.trim());

  void endRemovalConfirm(String url) => _confirmingRemoval.remove(url.trim());

  List<FavoriteArticle> get favorites => ref.read(libraryControllerProvider);

  String get trimmedQuery => state.searchQuery.trim();

  List<FavoriteArticle> get filteredFavorites {
    final query = trimmedQuery.toLowerCase();
    if (query.isEmpty) return favorites;

    bool matches(String? value) =>
        value != null && value.toLowerCase().contains(query);

    return favorites
        .where(
          (item) =>
              item.title.toLowerCase().contains(query) ||
              matches(item.author) ||
              matches(item.domain),
        )
        .toList();
  }

  /// Removes an article, its cached metadata and its saved body together.
  Future<void> removeFavorite(String url) async {
    final key = url.trim();
    if (key.isEmpty || !_removing.add(key)) return;

    try {
      await ref.read(libraryControllerProvider.notifier).remove(key);
    } finally {
      _removing.remove(key);
    }
  }

  void bumpDismissEpoch() {
    state = state.copyWith(dismissEpoch: state.dismissEpoch + 1);
  }

  void onSearchChanged(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

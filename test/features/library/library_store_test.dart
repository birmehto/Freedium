import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/storage/key_value_store.dart';
import 'package:freedium/core/storage/library_store.dart';

void main() {
  late LibraryStore store;

  setUp(() {
    store = LibraryStore(MemoryKeyValueStore());
  });

  group('LibraryStore favorites', () {
    test('starts empty and revises on mutations', () async {
      expect(store.favorites, isEmpty);
      final rev = store.favoritesRevision.value;

      await store.addToFavorites({'url': 'u1', 'title': 'T1'});
      expect(store.favorites, hasLength(1));
      expect(store.favoritesRevision.value, rev + 1);

      await store.removeFromFavorites('u1');
      expect(store.isFavorite('u1'), isFalse);
    });

    test('addToFavorites de-duplicates by url', () async {
      await store.addToFavorites({'url': 'u1', 'title': 'Old'});
      await store.addToFavorites({'url': 'u1', 'title': 'New'});
      expect(store.favorites, hasLength(1));
      expect(store.favorites.first['title'], 'New');
    });
  });
}

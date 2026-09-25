import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/storage/key_value_store.dart';
import 'package:freedium/core/storage/library_store.dart';
import 'package:freedium/features/article/models/article_meta.dart';
import 'package:freedium/features/favorites/models/favorite_article.dart';

FavoriteArticle article(String url, {String title = 'Title'}) =>
    FavoriteArticle(title: title, url: url, visitedAt: DateTime.utc(2026));

ArticleMeta meta(String title) => ArticleMeta(
  title: title,
  author: 'Author',
  publication: 'Pub',
  wordCount: 600,
  publishedAt: DateTime.utc(2026, 1, 2),
);

void main() {
  late MemoryKeyValueStore backing;
  late LibraryStore store;

  setUp(() {
    backing = MemoryKeyValueStore();
    store = LibraryStore(backing);
  });

  group('favorites', () {
    test('starts empty', () {
      expect(store.favorites, isEmpty);
      expect(store.isFavorite('https://medium.com/a'), isFalse);
    });

    test('adds and persists an article', () async {
      await store.addToFavorites(article('https://medium.com/a'));

      expect(store.favorites, hasLength(1));
      expect(store.favorites.first.title, 'Title');
      expect(store.isFavorite('https://medium.com/a'), isTrue);
      expect(backing.read(LibraryStore.favoritesKey), isNotNull);
    });

    test('re-adding the same URL replaces instead of duplicating', () async {
      await store.addToFavorites(article('https://medium.com/a', title: 'Old'));
      await store.addToFavorites(article('https://medium.com/a', title: 'New'));

      expect(store.favorites, hasLength(1));
      expect(store.favorites.single.title, 'New');
    });

    test('most recently added is first', () async {
      await store.addToFavorites(article('https://medium.com/a'));
      await store.addToFavorites(article('https://medium.com/b'));

      expect(store.favorites.first.url, 'https://medium.com/b');
    });

    test('removes by URL', () async {
      await store.addToFavorites(article('https://medium.com/a'));
      await store.removeFromFavorites('https://medium.com/a');

      expect(store.favorites, isEmpty);
      expect(store.isFavorite('https://medium.com/a'), isFalse);
    });

    test('removing an unknown URL is a no-op', () async {
      await store.addToFavorites(article('https://medium.com/a'));
      await store.removeFromFavorites('https://medium.com/other');

      expect(store.favorites, hasLength(1));
    });

    test('toggleFavorite reports the resulting state', () async {
      expect(
        await store.toggleFavorite(article('https://medium.com/a')),
        isTrue,
      );
      expect(store.isFavorite('https://medium.com/a'), isTrue);

      expect(
        await store.toggleFavorite(article('https://medium.com/a')),
        isFalse,
      );
      expect(store.isFavorite('https://medium.com/a'), isFalse);
    });

    test('rehydrates favorites written by an earlier session', () async {
      await store.addToFavorites(article('https://medium.com/a'));

      final reopened = LibraryStore(backing);
      expect(reopened.favorites.single.url, 'https://medium.com/a');
    });

    test('notifies observers on add and on remove', () async {
      var notifications = 0;
      store.favorites.listen((_) => notifications++);

      await store.addToFavorites(article('https://medium.com/a'));
      final afterAdd = notifications;
      expect(afterAdd, greaterThan(0));

      await store.removeFromFavorites('https://medium.com/a');
      expect(notifications, greaterThan(afterAdd));
    });
  });

  group('article metadata cache', () {
    test('is empty before anything is cached', () {
      expect(store.metaFor('https://medium.com/a'), isNull);
    });

    test('round-trips a cached entry', () async {
      await store.cacheMeta('https://medium.com/a', meta('Title'));

      final cached = store.metaFor('https://medium.com/a');
      expect(cached?.title, 'Title');
      expect(cached?.author, 'Author');
      expect(cached?.wordCount, 600);
      expect(cached?.publishedAt, DateTime.utc(2026, 1, 2));
    });

    test('caching a second article keeps the first', () async {
      await store.cacheMeta('https://medium.com/a', meta('First'));
      await store.cacheMeta('https://medium.com/b', meta('Second'));

      expect(store.metaFor('https://medium.com/a')?.title, 'First');
      expect(store.metaFor('https://medium.com/b')?.title, 'Second');
    });

    test('re-caching a URL overwrites only that entry', () async {
      await store.cacheMeta('https://medium.com/a', meta('Old'));
      await store.cacheMeta('https://medium.com/a', meta('New'));

      expect(store.metaFor('https://medium.com/a')?.title, 'New');
    });

    test('survives a restart', () async {
      await store.cacheMeta('https://medium.com/a', meta('Title'));
      expect(
        LibraryStore(backing).metaFor('https://medium.com/a')?.title,
        'Title',
      );
    });
  });
}

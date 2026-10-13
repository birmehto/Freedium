import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/storage/app_database.dart';
import 'package:freedium/core/storage/article_cache_store.dart';
import 'package:freedium/features/article/models/article_meta.dart';

/// Covers the offline article cache against a real (in-memory) database.
///
/// The point of the cache is that a story survives a dead mirror, so the tests
/// are about what a reader gets back and what the store is allowed to throw
/// away.
void main() {
  late AppDatabase database;
  late ArticleCacheStore cache;

  const url = 'https://medium.com/@someone/a-story-abc123';

  String body(int length) => '<p>${'x' * (length - 7)}</p>';

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    cache = ArticleCacheStore(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('saving and reading', () {
    test('starts empty', () async {
      expect(await cache.read(url), isNull);
      expect(await cache.contains(url), isFalse);
      expect(cache.cachedCount.value, 0);
      expect(cache.cachedBytes.value, 0);
    });

    test('round-trips an article body', () async {
      final saved = await cache.save(
        url: url,
        html: '<article><h1>Hello</h1></article>',
        title: 'Hello',
        author: 'Ada',
        publication: 'Medium',
        domain: 'medium.com',
        wordCount: 1200,
      );

      expect(saved, isTrue);

      final cached = await cache.read(url);
      expect(cached?.html, '<article><h1>Hello</h1></article>');
      expect(cached?.title, 'Hello');
      expect(cached?.author, 'Ada');
      expect(cached?.publication, 'Medium');
      expect(cached?.domain, 'medium.com');
      expect(cached?.wordCount, 1200);
      expect(await cache.contains(url), isTrue);
    });

    test('saveWithMeta carries the extracted metadata', () async {
      await cache.saveWithMeta(
        url: url,
        html: '<article>body</article>',
        meta: const ArticleMeta(
          title: 'Meta Title',
          author: 'Meta Author',
          wordCount: 400,
        ),
        domain: 'medium.com',
      );

      final cached = await cache.read(url);
      expect(cached?.title, 'Meta Title');
      expect(cached?.author, 'Meta Author');
      expect(cached?.wordCount, 400);
      expect(cached?.domain, 'medium.com');
    });

    test('an empty body is not cached', () async {
      expect(await cache.save(url: url, html: '   '), isFalse);
      expect(await cache.contains(url), isFalse);
    });

    test('a blank URL is not cached', () async {
      expect(await cache.save(url: '  ', html: '<p>hi</p>'), isFalse);
    });

    test(
      're-saving the same URL replaces the body instead of adding one',
      () async {
        await cache.save(url: url, html: body(1000), title: 'First');
        await cache.save(url: url, html: body(2000), title: 'Second');

        expect(await cache.contains(url), isTrue);
        expect(cache.cachedCount.value, 1);
        expect((await cache.read(url))?.title, 'Second');
      },
    );

    test('counts bytes, not characters, for multi-byte text', () async {
      // Each 'é' is one character but two UTF-8 bytes, and the ceiling is
      // expressed in bytes, so the total has to be measured the same way.
      await cache.save(url: url, html: 'é' * 100);

      expect(cache.cachedBytes.value, 200);
    });

    test('a non-ASCII article over the byte cap is skipped', () async {
      final huge = 'é' * ArticleCacheStore.maxArticleBytes;

      expect(await cache.save(url: url, html: huge), isFalse);
      expect(await cache.contains(url), isFalse);
    });

    test('tracks the total size across articles', () async {
      await cache.save(url: 'https://medium.com/a', html: body(1000));
      await cache.save(url: 'https://medium.com/b', html: body(2000));

      expect(cache.cachedCount.value, 2);
      expect(cache.cachedBytes.value, 3000);
    });

    test('a smaller replacement shrinks the tracked total', () async {
      await cache.save(url: url, html: body(3000));
      await cache.save(url: url, html: body(500));

      expect(cache.cachedCount.value, 1);
      expect(cache.cachedBytes.value, 500);
    });

    test('survives a restart', () async {
      await cache.save(
        url: url,
        html: '<article>kept</article>',
        title: 'Kept',
      );

      final reopened = ArticleCacheStore(database);
      await reopened.refreshTotals();

      expect((await reopened.read(url))?.html, '<article>kept</article>');
      expect(reopened.cachedCount.value, 1);
      expect(reopened.cachedBytes.value, '<article>kept</article>'.length);
    });
  });

  group('oversized articles', () {
    test('an article over the per-article cap is skipped', () async {
      final huge = 'x' * (ArticleCacheStore.maxArticleBytes + 1);

      final saved = await cache.save(url: url, html: huge);

      expect(saved, isFalse);
      expect(await cache.contains(url), isFalse);
      expect(cache.cachedCount.value, 0);
    });
  });

  group('eviction', () {
    /// Caches articles at the per-article cap.
    ///
    /// The cap is a third of the total budget's log, so only a dozen of these
    /// are needed to push the cache past it — which is the situation eviction
    /// exists for.
    Future<int> fillTo(int articles, {Iterable<String> keep = const []}) async {
      final filler = 'x' * ArticleCacheStore.maxArticleBytes;

      for (var i = 0; i < articles; i++) {
        await cache.save(
          url: 'https://medium.com/$i',
          html: filler,
          keep: keep,
        );
      }

      return articles;
    }

    test('the oldest article is dropped once the budget is exceeded', () async {
      // 12 fill the budget exactly; the thirteenth cannot fit.
      await fillTo(13);

      expect(
        cache.cachedBytes.value,
        lessThanOrEqualTo(ArticleCacheStore.maxCacheBytes),
      );
      expect(cache.cachedCount.value, 12);
      expect(await cache.contains('https://medium.com/0'), isFalse);
      expect(await cache.contains('https://medium.com/1'), isTrue);
      expect(await cache.contains('https://medium.com/12'), isTrue);
    });

    test('a pinned article is spared and the next oldest is dropped', () async {
      final pinned = ['https://medium.com/0'];

      for (var i = 0; i < 12; i++) {
        await cache.save(
          url: 'https://medium.com/$i',
          html: 'x' * ArticleCacheStore.maxArticleBytes,
          keep: pinned,
        );
      }

      await cache.save(
        url: 'https://medium.com/12',
        html: 'x' * ArticleCacheStore.maxArticleBytes,
        keep: pinned,
      );

      expect(await cache.contains('https://medium.com/0'), isTrue);
      expect(await cache.contains('https://medium.com/1'), isFalse);
    });

    test('an article is not evicted by the save that wrote it', () async {
      final cached = List.generate(12, (i) => 'https://medium.com/$i');

      for (final url in cached) {
        await cache.save(
          url: url,
          html: 'x' * ArticleCacheStore.maxArticleBytes,
          keep: cached,
        );
      }

      // Every earlier article is pinned, so the only way to fit this one is to
      // drop the article being written.
      await cache.save(
        url: 'https://medium.com/new',
        html: 'x' * ArticleCacheStore.maxArticleBytes,
        keep: cached,
      );

      expect(await cache.contains('https://medium.com/new'), isTrue);
    });

    test('pinned articles do not block eviction of the rest', () async {
      // Pinned rows used to be skipped inside the eviction loop, so a batch of
      // eight of them (as happens when the reader has many favorites) freed
      // nothing and the cache could never get back under its ceiling.
      final pinned = List.generate(8, (i) => 'https://medium.com/saved-$i');

      for (final url in pinned) {
        await cache.save(
          url: url,
          html: 'x' * ArticleCacheStore.maxArticleBytes,
          keep: pinned,
        );
      }

      await cache.save(
        url: 'https://medium.com/new',
        html: 'x' * ArticleCacheStore.maxArticleBytes,
        keep: pinned,
      );

      for (final url in pinned) {
        expect(await cache.contains(url), isTrue);
      }
      expect(
        cache.cachedBytes.value,
        lessThanOrEqualTo(ArticleCacheStore.maxCacheBytes),
      );
    });

    test('a cache inside its budget is left alone', () async {
      await cache.save(url: url, html: body(500));

      expect(await cache.contains(url), isTrue);
      expect(cache.cachedCount.value, 1);
    });
  });

  group('removing', () {
    test('remove drops one article and updates the totals', () async {
      await cache.save(url: url, html: body(1000));
      await cache.save(url: 'https://medium.com/other', html: body(500));

      await cache.remove(url);

      expect(await cache.contains(url), isFalse);
      expect(cache.cachedCount.value, 1);
      expect(cache.cachedBytes.value, 500);
    });

    test('removing an unknown article changes nothing', () async {
      await cache.save(url: url, html: body(1000));

      await cache.remove('https://medium.com/missing');

      expect(cache.cachedCount.value, 1);
      expect(cache.cachedBytes.value, 1000);
    });
  });

  group('refreshTotals', () {
    test('reports megabytes from what is on disk', () async {
      // Written straight to the table: [save] refuses anything over the
      // per-article cap, which is deliberately well below the cache budget.
      await database
          .into(database.cachedArticles)
          .insert(
            CachedArticlesCompanion.insert(
              url: url,
              html: 'x' * (1024 * 1024 + 512 * 1024),
              savedAt: DateTime.now(),
            ),
          );

      await cache.refreshTotals();

      expect(cache.cachedCount.value, 1);
      expect(cache.cachedBytes.value, 1024 * 1024 + 512 * 1024);
    });
  });
}

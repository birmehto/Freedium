import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/storage/key_value_store.dart';
import 'package:freedium/core/storage/library_store.dart';
import 'package:freedium/features/article/models/reading_progress.dart';
import 'package:freedium/features/article/models/saved_article.dart';
import 'package:freedium/features/library/models/history_entry.dart';

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

  group('LibraryStore history', () {
    test('recordHistory inserts at the front and dedupes', () {
      store.recordHistory(const HistoryEntry(title: 'A', url: 'u/a'));
      store.recordHistory(const HistoryEntry(title: 'B', url: 'u/b'));
      store.recordHistory(const HistoryEntry(title: 'A2', url: 'u/a'));

      expect(store.history, hasLength(2));
      expect(store.history.first.url, 'u/a');
      expect(store.history.first.title, 'A2');
    });

    test('updateHistory falls back to insertion when missing', () {
      store.updateHistory(const HistoryEntry(title: 'X', url: 'u/x'));
      expect(store.historyFor('u/x'), isNotNull);
    });

    test('removeHistory and clearHistory', () {
      store.recordHistory(const HistoryEntry(title: 'A', url: 'u/a'));
      store.recordHistory(const HistoryEntry(title: 'B', url: 'u/b'));
      store.removeHistory('u/a');
      expect(store.history, hasLength(1));

      store.clearHistory();
      expect(store.history, isEmpty);
    });
  });

  group('LibraryStore reading progress', () {
    test('defaults to zero progress', () {
      final p = store.getReadingProgress('u/missing');
      expect(p.progress, 0);
      expect(p.scrollY, 0);
    });

    test('round-trips progress including completion', () {
      final now = DateTime.now();
      store.saveReadingProgress(
        'u/1',
        ReadingProgress(
          progress: 0.8,
          scrollY: 1200,
          startedAt: now,
          lastReadAt: now,
        ),
      );
      var p = store.getReadingProgress('u/1');
      expect(p.progress, 0.8);
      expect(p.scrollY, 1200);
      expect(p.isCompleted, isFalse);

      store.saveReadingProgress(
        'u/1',
        p.copyWith(progress: 1.0, completedAt: now),
      );
      p = store.getReadingProgress('u/1');
      expect(p.isCompleted, isTrue);

      store.clearReadingProgress('u/1');
      expect(store.getReadingProgress('u/1').progress, 0);
    });

    test('legacy numeric progress still parses', () {
      final legacy = MemoryKeyValueStore()
        ..write(LibraryStore.kReadingProgress, {'u/legacy': 0.5});
      final s = LibraryStore(legacy);
      expect(s.getReadingProgress('u/legacy').progress, 0.5);
    });
  });

  group('LibraryStore saved articles', () {
    test('saveArticle persists and isSaved matches', () {
      final ok = store.saveArticle(
        const SavedArticle(title: 'Story', url: 'u/1', html: '<p>hi</p>'),
      );
      expect(ok, isTrue);
      expect(store.isSaved('u/1'), isTrue);
      expect(store.savedArticles, hasLength(1));
      expect(store.savedBytes, greaterThan(0));
    });

    test('re-saving the same url replaces the entry', () {
      store.saveArticle(const SavedArticle(title: 'A', url: 'u/1', html: 'a'));
      store.saveArticle(const SavedArticle(title: 'B', url: 'u/1', html: 'b'));
      expect(store.savedArticles, hasLength(1));
      expect(store.savedArticles.first.title, 'B');
    });

    test('removeSavedArticle and clearSavedArticles', () {
      store.saveArticle(const SavedArticle(title: 'A', url: 'u/1', html: 'a'));
      store.removeSavedArticle('u/1');
      expect(store.isSaved('u/1'), isFalse);

      store.saveArticle(const SavedArticle(title: 'B', url: 'u/2', html: 'b'));
      store.clearSavedArticles();
      expect(store.savedArticles, isEmpty);
    });
  });

  group('LibraryStore reading stats', () {
    test('starts at zero', () {
      expect(store.readingStats['openCount'], 0);
      expect(store.readingStats['readingMinutes'], 0);
      expect(store.readingStats['completedCount'], 0);
    });

    test('recordReadSession accumulates deltas', () {
      store.recordReadSession(openCountDelta: 1);
      store.recordReadSession(readingMinutes: 12);
      store.recordReadSession(completed: true);

      expect(store.readingStats['openCount'], 1);
      expect(store.readingStats['readingMinutes'], 12);
      expect(store.readingStats['completedCount'], 1);
    });
  });

  group('LibraryStore revisions', () {
    test('libraryRevision bumps on content mutation', () {
      final rev = store.libraryRevision.value;
      store.recordHistory(const HistoryEntry(title: 'A', url: 'u/1'));
      expect(store.libraryRevision.value, rev + 1);
    });
  });
}

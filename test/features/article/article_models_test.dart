import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/features/article/models/article_meta.dart';
import 'package:freedium/features/article/models/reading_progress.dart';
import 'package:freedium/features/article/models/saved_article.dart';
import 'package:freedium/features/library/models/history_entry.dart';

void main() {
  group('ArticleMeta', () {
    test('fromJson parses all fields', () {
      final meta = ArticleMeta.fromJson(const {
        'title': 'The Future of Flutter',
        'author': 'John Doe',
        'publication': 'Medium',
        'publishedAt': '2026-09-18T10:00:00.000Z',
        'wordCount': 1600,
      });
      expect(meta.title, 'The Future of Flutter');
      expect(meta.author, 'John Doe');
      expect(meta.publication, 'Medium');
      expect(meta.publishedAt, isNotNull);
      expect(meta.wordCount, 1600);
      expect(meta.readingTimeMinutes, 8);
    });

    test('fromJson tolerates null or partial maps', () {
      final meta = ArticleMeta.fromJson(null);
      expect(meta.title, '');
      expect(meta.author, isNull);
      final partial = ArticleMeta.fromJson(const {'title': 'Only title'});
      expect(partial.wordCount, 0);
      expect(partial.readingTimeMinutes, 0);
    });

    test('toJson/fromJson round-trip', () {
      const meta = ArticleMeta(
        title: 'T',
        author: 'A',
        publication: 'P',
        wordCount: 100,
      );
      final restored = ArticleMeta.fromJson(meta.toJson());
      expect(restored.title, 'T');
      expect(restored.author, 'A');
      expect(restored.wordCount, 100);
    });
  });

  group('ReadingProgress', () {
    test('completion detection uses completedAt', () {
      const incomplete = ReadingProgress(progress: 0.99);
      const complete = ReadingProgress(progress: 1.0);
      expect(incomplete.isCompleted, isFalse);
      expect(complete.isCompleted, isFalse);

      final done = incomplete.copyWith(completedAt: DateTime.now());
      expect(done.isCompleted, isTrue);
    });

    test('copyWith clears completion with flag', () {
      final done = ReadingProgress(completedAt: DateTime.now());
      final reopened = done.copyWith(progress: 0.2, clearCompleted: true);
      expect(reopened.isCompleted, isFalse);
    });
  });

  group('SavedArticle', () {
    test('round-trip and byte estimation', () {
      const article = SavedArticle(
        title: 'Story',
        url: 'u/1',
        html: 'hello',
        author: 'A',
        imageCount: 2,
      );
      final restored = SavedArticle.fromJson(article.toJson());
      expect(restored.title, 'Story');
      expect(restored.url, 'u/1');
      expect(restored.author, 'A');
      expect(restored.imageCount, 2);
      expect(restored.approximateBytes, greaterThan(200 * 1024));
    });
  });

  group('HistoryEntry', () {
    test('timeBucket bucketizes by recency', () {
      final now = DateTime.now();
      final today = now.subtract(const Duration(hours: 1));
      final yesterday = now.subtract(const Duration(days: 1));
      final lastWeek = now.subtract(const Duration(days: 6));
      final older = now.subtract(const Duration(days: 30));

      expect(
        HistoryEntry(title: 't', url: 'u', lastReadAt: today).timeBucket,
        'Today',
      );
      expect(
        HistoryEntry(title: 't', url: 'u', lastReadAt: yesterday).timeBucket,
        'Yesterday',
      );
      expect(
        HistoryEntry(title: 't', url: 'u', lastReadAt: lastWeek).timeBucket,
        'This week',
      );
      expect(
        HistoryEntry(title: 't', url: 'u', lastReadAt: older).timeBucket,
        'Earlier',
      );
    });

    test('round-trip preserves fields and defaults', () {
      const entry = HistoryEntry(
        title: 'T',
        url: 'u',
        author: 'A',
        progress: 0.5,
        completed: true,
      );
      final restored = HistoryEntry.fromJson(entry.toJson());
      expect(restored.title, 'T');
      expect(restored.author, 'A');
      expect(restored.progress, 0.5);
      expect(restored.completed, isTrue);

      final defaults = HistoryEntry.fromJson(const {});
      expect(defaults.title, 'Article');
      expect(defaults.progress, 0);
    });
  });
}

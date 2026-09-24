import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/features/article/models/article_meta.dart';
import 'package:freedium/features/article/models/saved_article.dart';

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
}

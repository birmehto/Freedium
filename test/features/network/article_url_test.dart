import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/network/article_url.dart';

void main() {
  group('ArticleUrl.canonicalize', () {
    test('strips tracking parameters and fragments', () {
      expect(
        ArticleUrl.canonicalize(
          'https://medium.com/@user/article-123?utm_source=twitter&utm_medium=social&foo=bar#section',
        ),
        'https://medium.com/@user/article-123?foo=bar',
      );
    });

    test('host and scheme are normalized to lowercase', () {
      expect(
        ArticleUrl.canonicalize('HTTP://Medium.COM/Story'),
        'http://medium.com/Story',
      );
    });

    test('empty and unparseable input yields empty string', () {
      expect(ArticleUrl.canonicalize(null), '');
      expect(ArticleUrl.canonicalize('   '), '');
      expect(ArticleUrl.canonicalize('not a url'), '');
    });

    test('only-tracking URLs are fully stripped to the path', () {
      expect(
        ArticleUrl.canonicalize(
          'https://medium.com/p/abc?utm_source=newsletter&gclid=x',
        ),
        'https://medium.com/p/abc',
      );
    });
  });

  group('ArticleUrl.cleanUrl', () {
    test('adds https to bare www and medium.com host', () {
      expect(
        ArticleUrl.cleanUrl('www.medium.com/article'),
        'https://www.medium.com/article',
      );
      expect(
        ArticleUrl.cleanUrl('medium.com/@user/demo'),
        'https://medium.com/@user/demo',
      );
    });

    test('extracts URL from markdown link', () {
      expect(
        ArticleUrl.cleanUrl('[Read this](https://medium.com/some-doc)'),
        'https://medium.com/some-doc',
      );
    });

    test('rejects non-URLs', () {
      expect(ArticleUrl.cleanUrl('hello world'), isNull);
      expect(ArticleUrl.cleanUrl(''), isNull);
    });
  });

  group('ArticleUrl.isMediumUrl', () {
    test('is true for medium.com and subdomains', () {
      expect(ArticleUrl.isMediumUrl(Uri.parse('https://medium.com/x')), isTrue);
      expect(
        ArticleUrl.isMediumUrl(Uri.parse('https://blog.medium.com/x')),
        isTrue,
      );
    });

    test('is false for non-Medium hosts including publications', () {
      expect(
        ArticleUrl.isMediumUrl(Uri.parse('https://example.com/x')),
        isFalse,
      );
      expect(
        ArticleUrl.isMediumUrl(Uri.parse('https://towardsdatascience.com/x')),
        isFalse,
      );
    });
  });

  group('ArticleUrl.isSupported', () {
    test('only HTTP(S) schemes', () {
      expect(ArticleUrl.isSupported(Uri.parse('https://medium.com/x')), isTrue);
      expect(ArticleUrl.isSupported(Uri.parse('http://medium.com/x')), isTrue);
      expect(ArticleUrl.isSupported(Uri.parse('javascript:alert(1)')), isFalse);
    });
  });

  group('ArticleUrl.extractFirstUrl', () {
    test('single URL payload', () {
      expect(
        ArticleUrl.extractFirstUrl('https://medium.com/story'),
        'https://medium.com/story',
      );
    });

    test('free text containing an URL', () {
      expect(
        ArticleUrl.extractFirstUrl(
          'Check out https://towardsdatascience.com/a-b <3',
        ),
        'https://towardsdatascience.com/a-b',
      );
    });

    test('empty or null payload', () {
      expect(ArticleUrl.extractFirstUrl(null), isNull);
      expect(ArticleUrl.extractFirstUrl('  '), isNull);
    });
  });
}

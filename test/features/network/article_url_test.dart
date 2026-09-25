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

    test('the same article produces the same URL regardless of tracking', () {
      expect(
        ArticleUrl.canonicalize(
          'https://medium.com/p/abc?utm_source=newsletter',
        ),
        ArticleUrl.canonicalize('https://medium.com/p/abc?fbclid=xyz'),
      );
    });
  });

  group('ArticleUrl.normalize', () {
    test('adds https to a bare host', () {
      expect(
        ArticleUrl.normalize('www.medium.com/article'),
        'https://www.medium.com/article',
      );
      expect(
        ArticleUrl.normalize('medium.com/@user/demo'),
        'https://medium.com/@user/demo',
      );
    });

    test('extracts the URL from a markdown link', () {
      expect(
        ArticleUrl.normalize('[Read this](https://medium.com/some-doc)'),
        'https://medium.com/some-doc',
      );
    });

    test('rejects non-URLs and unsupported schemes', () {
      expect(ArticleUrl.normalize('hello world'), isNull);
      expect(ArticleUrl.normalize(''), isNull);
      expect(ArticleUrl.normalize('ftp://medium.com/story'), isNull);
      expect(ArticleUrl.normalize('javascript:alert(1)'), isNull);
    });
  });

  group('ArticleUrl.isValid', () {
    test('accepts any http(s) URL with a real host', () {
      expect(ArticleUrl.isValid('https://medium.com/x'), isTrue);
      expect(ArticleUrl.isValid('https://google.com'), isTrue);
      expect(ArticleUrl.isValid('http://localhost:8080/a'), isFalse);
    });

    test('rejects empty, hostless and non-URL input', () {
      expect(ArticleUrl.isValid(null), isFalse);
      expect(ArticleUrl.isValid(''), isFalse);
      expect(ArticleUrl.isValid('not-a-valid-url'), isFalse);
      expect(ArticleUrl.isValid('https://'), isFalse);
    });
  });

  group('ArticleUrl.validationError', () {
    test('accepts a valid URL', () {
      expect(ArticleUrl.validationError('https://medium.com/x'), isNull);
    });

    test('distinguishes empty input from invalid input', () {
      expect(ArticleUrl.validationError(''), 'Please enter a URL');
      expect(
        ArticleUrl.validationError('not-a-valid-url'),
        'Please enter a valid URL',
      );
    });

    test('agrees with isValid', () {
      for (final input in ['', 'nope', 'https://medium.com/a']) {
        expect(
          ArticleUrl.validationError(input) == null,
          ArticleUrl.isValid(input),
        );
      }
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

    test('free text containing a URL', () {
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
      expect(ArticleUrl.extractFirstUrl('no link here'), isNull);
    });
  });

  group('ArticleUrl.hostOf', () {
    test('drops a leading www', () {
      expect(ArticleUrl.hostOf('https://www.medium.com/x'), 'medium.com');
    });

    test('is null for unusable URLs', () {
      expect(ArticleUrl.hostOf('nope'), isNull);
    });
  });
}

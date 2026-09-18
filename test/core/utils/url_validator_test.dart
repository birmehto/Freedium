import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/utils/url_validator.dart';

void main() {
  group('UrlValidator', () {
    test('extractUrlFromText finds URL in shared text', () {
      const text =
          'Read "I Made My Flutter App Load 3x Faster" by Abhinav on Medium: https://codingplainenglish.medium.com/article-id';
      final result = UrlValidator.extractUrlFromText(text);
      expect(result, 'https://codingplainenglish.medium.com/article-id');
    });

    test('extractUrlFromText returns null when no URL is present', () {
      const text = 'Just some random text with no links.';
      final result = UrlValidator.extractUrlFromText(text);
      expect(result, null);
    });

    test('cleanTextiseUrl extracts target URL from Textise wrapper', () {
      const textiseUrl =
          'http://textise.org/showtext.aspx?strURL=https://codingplainenglish.medium.com/i-made-my-flutter-app-load-3x-faster-heres-the-exact-optimization-ec2ca3617f2f';
      final result = UrlValidator.cleanTextiseUrl(textiseUrl);
      expect(
        result,
        'https://codingplainenglish.medium.com/i-made-my-flutter-app-load-3x-faster-heres-the-exact-optimization-ec2ca3617f2f',
      );
    });

    test('cleanTextiseUrl returns original URL if not Textise', () {
      const url = 'https://medium.com';
      final result = UrlValidator.cleanTextiseUrl(url);
      expect(result, url);
    });

    test(
      'cleanTextiseUrl handles Textise URL without strURL param gracefully',
      () {
        const url = 'http://textise.org/showtext.aspx';
        final result = UrlValidator.cleanTextiseUrl(url);
        expect(result, url);
      },
    );

    test('isValidUrl accepts standard medium.com URLs', () {
      expect(
        UrlValidator.isValidUrl('https://medium.com/story-title-abc'),
        true,
      );
      expect(
        UrlValidator.isValidUrl('https://medium.com/@user/post-123'),
        true,
      );
      expect(
        UrlValidator.isValidUrl('https://plainenglish.medium.com/post-456'),
        true,
      );
      expect(UrlValidator.isValidUrl('https://sub.medium.com/x/y/z'), true);
    });

    test('isValidUrl rejects malformed URLs', () {
      expect(UrlValidator.isValidUrl('not a url'), false);
      expect(UrlValidator.isValidUrl('ftp://medium.com/post'), false);
      expect(UrlValidator.isValidUrl('https://'), false);
      expect(UrlValidator.isValidUrl(''), false);
    });

    test('isValidUrl accepts a bare domain host', () {
      expect(UrlValidator.isValidUrl('https://medium.com'), true);
    });

    test('cleanUrl normalizes URLs without a scheme', () {
      expect(
        UrlValidator.cleanUrl('medium.com/@user/post-abc'),
        'https://medium.com/@user/post-abc',
      );
      expect(
        UrlValidator.cleanUrl('  https://medium.com/post-abc  '),
        'https://medium.com/post-abc',
      );
    });

    test('cleanUrl returns null for invalid input', () {
      expect(UrlValidator.cleanUrl(''), isNull);
      expect(UrlValidator.cleanUrl('123abc'), isNull);
    });

    test('extractUrlFromText strips trailing punctuation', () {
      const text =
          'Check this: https://medium.com/post-123?utm_source=share, thanks!';
      final result = UrlValidator.extractUrlFromText(text);
      expect(result, 'https://medium.com/post-123?utm_source=share');
    });

    test('convertToFreediumUrl wraps a plain medium URL', () {
      final result = UrlValidator.convertToFreediumUrl(
        'https://medium.com/post-abc',
      );
      expect(result, 'https://freedium-mirror.cfd/https://medium.com/post-abc');
    });

    test('convertToFreediumUrl is idempotent for freedium URLs', () {
      const freedium = 'https://freedium-mirror.cfd/https://medium.com/post';
      final result = UrlValidator.convertToFreediumUrl(freedium);
      expect(result, freedium);
    });
  });
}

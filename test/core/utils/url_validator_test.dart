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
  });
}

import '../constants/app_constants.dart';

class UrlValidator {
  static const String _urlPattern =
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$';
  static final RegExp _urlRegex = RegExp(_urlPattern);

  /// Validate if the string is a valid URL
  static bool isValidUrl(String url) {
    if (url.isEmpty) return false;
    return _urlRegex.hasMatch(url);
  }

  /// Extract any URL found in the text and clean it
  static String? extractUrlFromText(String text) {
    if (text.isEmpty) return null;

    final RegExp urlFinder = RegExp(
      r'(https?:\/\/[^\s]+)',
      caseSensitive: false,
    );

    final match = urlFinder.firstMatch(text);
    if (match == null) return null;

    String url = match.group(0)!;

    while (url.isNotEmpty &&
        (url.endsWith('.') ||
            url.endsWith(',') ||
            url.endsWith('!') ||
            url.endsWith('?') ||
            url.endsWith(';') ||
            url.endsWith(':'))) {
      url = url.substring(0, url.length - 1);
    }

    return url;
  }

  /// Convert any URL to Freedium URL for reading
  static String? convertToFreediumUrl(String articleUrl) {
    if (!isValidUrl(articleUrl)) return null;

    String targetUrl = cleanUrl(articleUrl) ?? articleUrl;

    final prefixes = ['https://freedium-mirror.cfd/', 'https://freedium.cfd/'];

    bool stripped = true;
    while (stripped) {
      stripped = false;
      for (final prefix in prefixes) {
        if (targetUrl.startsWith(prefix)) {
          targetUrl = targetUrl.substring(prefix.length);
          stripped = true;
        }
      }
    }

    const activeEngine = MediumConstants.freediumUrl;
    return '$activeEngine/$targetUrl';
  }

  /// Validate and clean URL
  static String? cleanUrl(String input) {
    if (input.isEmpty) return null;

    String cleaned = input.trim();

    if (!cleaned.startsWith('http://') && !cleaned.startsWith('https://')) {
      cleaned = 'https://$cleaned';
    }

    return isValidUrl(cleaned) ? cleaned : null;
  }

  /// Cleans Textise URLs to extract the actual target URL
  static String? cleanTextiseUrl(String url) {
    if (url.isEmpty) return null;

    if (url.contains('textise.org')) {
      final uri = Uri.tryParse(url);
      if (uri != null && uri.queryParameters.containsKey('strURL')) {
        return uri.queryParameters['strURL'];
      }
    }
    return url;
  }
}

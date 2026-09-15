import '../constants/app_constants.dart';

class UrlValidator {
  static final _urlRegex = RegExp(r'^https?://[^\s]+$');
  static final _textUrlRegex = RegExp(r'https?://[^\s]+', caseSensitive: false);

  static bool isValidUrl(String url) {
    final trimmed = url.trim();
    final uri = Uri.tryParse(trimmed);
    return _urlRegex.hasMatch(trimmed) && uri != null && uri.host.contains('.');
  }

  static String? cleanUrl(String input) {
    final url = input.trim();
    if (url.isEmpty) return null;

    final normalized = url.startsWith(RegExp('https?://'))
        ? url
        : 'https://$url';

    return isValidUrl(normalized) ? normalized : null;
  }

  static String? extractUrlFromText(String text) {
    final match = _textUrlRegex.firstMatch(text);
    if (match == null) return null;

    return match.group(0)?.replaceFirst(RegExp(r'[.,!?;:]+$'), '');
  }

  static String? convertToFreediumUrl(String articleUrl) {
    final url = cleanUrl(articleUrl);
    if (url == null) return null;
    final target = url.startsWith(AppConstants.freediumUrl)
        ? url.substring(AppConstants.freediumUrl.length)
        : url;
    return '${AppConstants.freediumUrl}$target';
  }

  static String cleanTextiseUrl(String url) {
    final uri = Uri.tryParse(url);

    if (uri?.host.contains('textise.org') == true) {
      return uri!.queryParameters['strURL'] ?? url;
    }

    return url;
  }
}

/// Query parameters treated as tracking noise and stripped during
/// canonicalization.
const Set<String> kTrackingParams = {
  'utm_source',
  'utm_medium',
  'utm_campaign',
  'utm_term',
  'utm_content',
  'utm_id',
  'mc_cid',
  'mc_eid',
  'fbclid',
  'gclid',
  'gclsrc',
  'dclid',
  'igshid',
  'twclid',
  'ytclid',
  '_ga',
  'ref',
  'ref_src',
  'ref_url',
  'source',
  'src',
  'feature',
};

class ArticleUrl {
  ArticleUrl._();

  /// Strips tracking parameters, fragments and normalizes the host so that
  /// the same article is always recognized as one canonical URL.
  static String canonicalize(String? url) {
    final cleaned = cleanUrl(url);
    if (cleaned == null) return '';

    final uri = Uri.tryParse(cleaned);
    if (uri == null || !uri.hasScheme) return cleaned;

    final queryParams = <String, String>{};
    uri.queryParameters.forEach((key, value) {
      if (!kTrackingParams.contains(key.toLowerCase())) {
        queryParams[key] = value;
      }
    });

    return Uri(
      scheme: uri.scheme.toLowerCase(),
      host: uri.host.toLowerCase(),
      port: uri.hasPort ? uri.port : null,
      path: uri.path,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    ).toString();
  }

  /// Returns a normalized URL string or null when the input cannot be parsed.
  static String? cleanUrl(String? url) {
    if (url == null) return null;
    var trimmed = url.trim();

    final markdownMatch = RegExp(r'\[([^\]]*)\]\((https?://[^)]+)\)')
        .firstMatch(trimmed);
    if (markdownMatch != null) {
      trimmed = markdownMatch.group(2)!;
    } else if (trimmed.startsWith('www.')) {
      trimmed = 'https://$trimmed';
    } else if (trimmed.startsWith('medium.com')) {
      trimmed = 'https://$trimmed';
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) return null;
    return trimmed;
  }

  /// True when the URL points to a Medium-hosted article (medium.com,
  /// *.medium.com, or a Medium-/Freedium-proxied URL).
  static bool isMediumUrl(Uri uri) {
    final host = uri.host.toLowerCase();
    return host == 'medium.com' ||
        host.endsWith('.medium.com') ||
        host == 'freedium-mirror.cfd' ||
        host == 'freedium.cfd';
  }

  /// True when the URL is HTTP(S) and therefore supported by the reader.
  static bool isSupported(Uri uri) =>
      uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');

  /// First valid HTTP(S) URL found in a free-text share payload.
  static String? extractFirstUrl(String? payload) {
    if (payload == null || payload.trim().isEmpty) return null;
    if (payload.trim().split(RegExp(r'\s+')).length == 1) {
      final single = cleanUrl(payload);
      if (single != null) return single;
    }
    final match = RegExp(r'''https?://[^\s<>"'()\[\]]+''').firstMatch(payload);
    return cleanUrl(match?.group(0));
  }
}

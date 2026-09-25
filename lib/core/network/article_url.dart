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

/// Matches a bare URL inside a larger block of share text.
final RegExp _urlInText = RegExp(r'''https?://[^\s<>"'()\[\]]+''');

final RegExp _whitespace = RegExp(r'\s');

/// A dotted hostname, e.g. `medium.com` or `blog.medium.co.uk`.
final RegExp _hostname = RegExp(
  r'^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$',
  caseSensitive: false,
);

/// The single source of truth for article URL handling.
///
/// Every entry point (home form, Android share intents, the library list and
/// the mirror resolver) normalizes through this class, so one article is always
/// recognized as one canonical URL and validation never disagrees with the code
/// that actually loads the article.
abstract final class ArticleUrl {
  /// Normalized http(s) URL, or `null` when [raw] cannot be interpreted as one.
  ///
  /// Accepts a full http(s) URL, a markdown link, or a bare host such as
  /// `medium.com/@user/post`, which is promoted to https.
  static String? normalize(String? raw) {
    if (raw == null) return null;

    var value = raw.trim();
    if (value.isEmpty) return null;

    final markdown = RegExp(r'\[([^\]]*)\]\((https?://[^)]+)\)')
        .firstMatch(value);
    if (markdown != null) {
      value = markdown.group(2)!;
    } else if (!value.contains('://')) {
      value = 'https://$value';
    }

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || !isSupported(uri)) return null;

    // A real hostname is required, so prose such as "hello world" or a bare
    // word is never mistaken for an article URL.
    if (!_hostname.hasMatch(uri.host)) return null;

    return value;
  }

  /// Strips tracking parameters and fragments and normalizes the host, so the
  /// same article always produces the same canonical URL.
  ///
  /// Returns an empty string when [raw] is not a usable article URL.
  static String canonicalize(String? raw) {
    final normalized = normalize(raw);
    if (normalized == null) return '';

    final uri = Uri.parse(normalized);
    if (uri.host.isEmpty || !uri.host.contains('.')) return '';

    final query = <String, String>{};
    uri.queryParameters.forEach((key, value) {
      if (!kTrackingParams.contains(key.toLowerCase())) {
        query[key] = value;
      }
    });

    return Uri(
      scheme: uri.scheme.toLowerCase(),
      host: uri.host.toLowerCase(),
      port: uri.hasPort ? uri.port : null,
      path: uri.path,
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }

  /// Form-validator message for [raw], or `null` when it is acceptable.
  static String? validationError(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return 'Please enter a URL';
    if (!isValid(value)) return 'Please enter a valid URL';
    return null;
  }

  /// True when the URI uses a scheme the reader can display.
  static bool isSupported(Uri uri) =>
      uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');

  /// True when the reader can open [raw].
  ///
  /// Defined as the single rule [normalize] applies, so a form can never
  /// validate a URL differently from the code that loads the article.
  static bool isValid(String? raw) => normalize(raw) != null;

  /// First http(s) URL found in a free-text share payload, or `null`.
  static String? extractFirstUrl(String? payload) {
    final text = payload?.trim() ?? '';
    if (text.isEmpty) return null;

    // A payload with no whitespace is a bare URL (or markdown link) the user
    // shared on purpose, so take it as-is.
    if (!_whitespace.hasMatch(text)) return normalize(text);

    return normalize(_urlInText.firstMatch(text)?.group(0));
  }

  /// The host without a leading `www.`, used for display and deduplication.
  static String? hostOf(String? url) {
    final canonical = canonicalize(url);
    if (canonical.isEmpty) return null;

    final host = Uri.parse(canonical).host;
    return host.startsWith('www.') ? host.substring(4) : host;
  }
}

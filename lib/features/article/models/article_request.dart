import '../../../core/network/article_url.dart';

/// Typed route payload for the article reader.
///
/// Replaces the untyped argument map so a wrong key or a missing URL is a
/// compile-time concern instead of a silent blank screen.
class ArticleRequest {
  const ArticleRequest({required this.url, this.originalUrl});

  /// Builds a request, canonicalizing [url] up front.
  factory ArticleRequest.parse(String? url) {
    final canonical = ArticleUrl.canonicalize(url);
    return ArticleRequest(url: canonical);
  }

  /// Canonical URL of the article to read.
  final String url;

  /// Original (pre-mirror) URL, when the reader should keep the publisher's
  /// link for sharing and favoriting. Defaults to [url].
  final String? originalUrl;

  /// The URL to share, favorite and display in metadata.
  String get sourceUrl => originalUrl?.isNotEmpty == true ? originalUrl! : url;

  /// False when the URL could not be canonicalized.
  bool get isValid => url.isNotEmpty;

  Map<String, dynamic> toArguments() => {
    'url': url,
    if (originalUrl != null) 'originalUrl': originalUrl,
  };

  static ArticleRequest fromArguments(Object? arguments) {
    if (arguments is ArticleRequest) return arguments;

    if (arguments is Map) {
      return ArticleRequest(
        url: ArticleUrl.canonicalize(arguments['url'] as String?),
        originalUrl: arguments['originalUrl'] as String?,
      );
    }

    return ArticleRequest.parse(arguments as String?);
  }
}

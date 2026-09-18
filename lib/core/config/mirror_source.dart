/// A backend that can render a Medium article without a paywall.
class MirrorSource {
  MirrorSource({
    required this.id,
    required this.name,
    required this.url,
    required this.urlTemplate,
    this.isTextOnly = false,
  });

  final String id;
  final String name;
  final String url;
  final bool isTextOnly;

  /// Template produces the final proxied URL from an original article URL.
  /// `{original}` is replaced with the URL-encoded original URL.
  final String urlTemplate;

  bool available = true;
  int consecutiveFailures = 0;
  int totalFailures = 0;
  DateTime? lastSuccessAt;
  DateTime? lastAttemptAt;
  Duration? lastResponseTime;

  String buildUrl(String originalUrl) =>
      urlTemplate.replaceAll('{original}', Uri.encodeComponent(originalUrl));

  void recordSuccess({Duration? responseTime}) {
    available = true;
    consecutiveFailures = 0;
    lastSuccessAt = DateTime.now();
    lastAttemptAt = DateTime.now();
    lastResponseTime = responseTime;
  }

  void recordFailure() {
    consecutiveFailures++;
    totalFailures++;
    lastAttemptAt = DateTime.now();
    if (consecutiveFailures >= 3) {
      available = false;
    }
  }

  /// Used by the resolver to retry mirrors that were temporarily disabled.
  void resetHealth() {
    consecutiveFailures = 0;
    available = true;
  }
}

/// Known mirror backends. The primary one is used first; the resolver
/// automatically falls back to the next available source on failure.
class MirrorCatalog {
  MirrorCatalog._();

  static final List<MirrorSource> defaults = [
    MirrorSource(
      id: 'freedium',
      name: 'Freedium',
      url: 'https://freedium-mirror.cfd/',
      urlTemplate: 'https://freedium-mirror.cfd/{original}',
    ),
    MirrorSource(
      id: 'textise',
      name: 'Textise',
      url: 'https://www.textise.net/',
      urlTemplate:
          'https://www.textise.net/showText.aspx?strURL={original}&opt=3',
      isTextOnly: true,
    ),
  ];
}

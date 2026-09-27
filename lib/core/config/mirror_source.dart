/// A backend that can render a Medium article without a paywall.
class MirrorSource {
  MirrorSource({
    required this.id,
    required this.name,
    required this.url,
    required this.urlTemplate,
  });

  final String id;
  final String name;

  /// Human-readable origin of the mirror, shown in Settings.
  final String url;

  /// Produces the proxied URL for an article; `{original}` is replaced with
  /// the URL-encoded original URL.
  final String urlTemplate;

  String get host => Uri.parse(url).host;

  // ── Health tracking (in-memory for the current session) ────────────────

  /// Consecutive failures before a mirror is taken out of rotation.
  static const int failureThreshold = 3;

  bool available = true;
  int consecutiveFailures = 0;

  String buildUrl(String originalUrl) =>
      urlTemplate.replaceAll('{original}', Uri.encodeComponent(originalUrl));

  void recordSuccess() {
    available = true;
    consecutiveFailures = 0;
  }

  void recordFailure() {
    consecutiveFailures++;
    if (consecutiveFailures >= failureThreshold) {
      available = false;
    }
  }

  /// Lets the resolver retry a mirror that was taken out of rotation.
  void resetHealth() {
    consecutiveFailures = 0;
    available = true;
  }
}

/// The known mirror backends, in the order they are attempted.
///
/// Every call returns fresh [MirrorSource] instances: health state must never be
/// shared between resolvers.
abstract final class MirrorCatalog {
  static List<MirrorSource> createDefaults() => [
    MirrorSource(
      id: 'freedium',
      name: 'Freedium',
      url: 'https://freedium-mirror.cfd/',
      urlTemplate: 'https://freedium-mirror.cfd/{original}',
    ),
    MirrorSource(
      id: 'mirror',
      name: 'Mirror',
      url: 'https://freedium-mirror-web.vercel.app/',
      urlTemplate: 'https://freedium-mirror-web.vercel.app/{original}',
    ),
  ];
}

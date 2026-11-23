/// A backend that can render a Medium article without a paywall.
class MirrorSource {
  MirrorSource({
    required this.id,
    required this.name,
    required this.url,
    required this.urlTemplate,
    this.aliases = const [],
  });

  final String id;
  final String name;

  /// Human-readable origin of the mirror, shown in Settings.
  final String url;

  /// Produces the proxied URL for an article.
  ///
  /// `{original}` is replaced with the URL-encoded original URL, while `{url}`
  /// is replaced with the original URL unchanged. Mirrors that take the target
  /// as a path segment want the encoded form; archive-style mirrors that take
  /// it as a prefix want the raw one.
  final String urlTemplate;

  /// Additional hosts the mirror may redirect to, e.g. the archive.today
  /// domain family. The reader treats them as in-app navigation rather than
  /// handing the redirect to the browser.
  final List<String> aliases;

  String get host => Uri.parse(url).host;

  /// [host] plus any redirect aliases, lowercased for comparison.
  Set<String> get allowedHosts => {
    host.toLowerCase(),
    for (final alias in aliases) alias.toLowerCase(),
  };

  // ── Health tracking (in-memory for the current session) ────────────────

  /// Consecutive failures before a mirror is taken out of rotation.
  static const int failureThreshold = 3;

  bool available = true;
  int consecutiveFailures = 0;

  String buildUrl(String originalUrl) => urlTemplate
      .replaceAll('{original}', Uri.encodeComponent(originalUrl))
      .replaceAll('{url}', originalUrl);

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
  /// The archive.today family all serves the same database under different
  /// top-level domains, so a mirror on one may redirect to another.
  static const List<String> _archiveHosts = [
    'archive.ph',
    'archive.is',
    'archive.today',
    'archive.md',
    'archive.li',
    'archive.vn',
    'archive.fo',
  ];

  static List<MirrorSource> createDefaults() => [
    MirrorSource(
      id: 'freedium',
      name: 'Freedium',
      url: 'https://freedium-mirror.cfd/',
      urlTemplate: 'https://freedium-mirror.cfd/{original}',
    ),
    MirrorSource(
      id: 'mirror',
      name: 'Freedium Web',
      url: 'https://freedium-mirror-web.vercel.app/',
      // This mirror takes the target as a query parameter, not a path suffix.
      // The old `/{original}` form answered every article with a 404.
      urlTemplate: 'https://freedium-mirror-web.vercel.app/read?url={original}',
    ),
    MirrorSource(
      id: 'freedium-legacy',
      name: 'Freedium (backup)',
      url: 'https://freedium.cfd/',
      urlTemplate: 'https://freedium.cfd/{original}',
    ),
    MirrorSource(
      id: 'archive-ph',
      name: 'Archive.ph',
      url: 'https://archive.ph/',
      urlTemplate: 'https://archive.ph/newest/{url}',
      aliases: _archiveHosts,
    ),
    MirrorSource(
      id: 'archive-is',
      name: 'Archive.is',
      url: 'https://archive.is/',
      urlTemplate: 'https://archive.is/newest/{url}',
      aliases: _archiveHosts,
    ),
  ];
}

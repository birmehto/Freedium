import '../config/mirror_source.dart';
import 'article_url.dart';

/// Resolves a canonical article URL to a mirror-proxied URL and tracks the
/// health of each backend so the reader fails over instead of showing a dead
/// end.
///
/// Registered as a single app-wide instance, so what the resolver learns about
/// one article helps the next one.
class ArticleResolver {
  ArticleResolver({List<MirrorSource>? sources})
    : _sources = sources ?? MirrorCatalog.createDefaults();

  final List<MirrorSource> _sources;

  String? _preferredSourceId;
  String? _lastOriginalUrl;
  String? _lastSourceId;
  bool autoFallback = true;

  List<MirrorSource> get sources => List.unmodifiable(_sources);

  String? get lastSourceId => _lastSourceId;

  String? get preferredSourceId => _preferredSourceId;

  /// The mirror currently serving (or about to serve) the article.
  MirrorSource? get activeSource =>
      _sources.where((source) => source.id == _lastSourceId).firstOrNull;

  /// Backends in the order they will be attempted: the user's preferred mirror
  /// first, then the remaining catalog order.
  List<MirrorSource> get candidates {
    final ordered = List<MirrorSource>.from(_sources);
    final preferred = _preferredSourceId;
    if (preferred == null) return ordered;

    ordered.sort((a, b) {
      if (a.id == preferred) return -1;
      if (b.id == preferred) return 1;
      return 0;
    });

    return ordered;
  }

  /// The proxied URL to load for [originalUrl], or `null` when the article URL
  /// is unusable.
  String? resolve(String originalUrl) {
    final canonical = ArticleUrl.canonicalize(originalUrl);
    if (canonical.isEmpty || _sources.isEmpty) return null;

    _lastOriginalUrl = canonical;

    // `candidates` puts the preferred mirror first, so preferring it while it is
    // healthy falls out of taking the first available entry. When the whole
    // catalog is unhealthy the first candidate is still tried, so the reader
    // always has somewhere to go.
    final source = candidates.firstWhere(
      (candidate) => candidate.available,
      orElse: () => candidates.first,
    );

    _lastSourceId = source.id;
    return source.buildUrl(canonical);
  }

  /// The next mirror to try after [_lastSourceId] failed, or `null` when
  /// fallback is disabled or there is nothing left to try.
  String? nextFallback() {
    if (!autoFallback) return null;

    final original = ArticleUrl.canonicalize(_lastOriginalUrl ?? '');
    if (original.isEmpty) return null;

    var healthy = candidates.where((source) => source.available).toList();

    // Everything is unhealthy: give the catalog a second chance rather than
    // leaving the reader with no source at all.
    if (healthy.isEmpty) {
      for (final source in _sources) {
        source.resetHealth();
      }
      healthy = candidates;
    }

    final currentId = _lastSourceId;
    final next = healthy.firstWhere(
      (source) => source.id != currentId,
      orElse: () => healthy.first,
    );

    // A single-mirror catalog has nowhere to fall back to; retrying the same
    // URL would just re-run the failure the caller already reported.
    if (next.id == currentId) return null;

    _lastSourceId = next.id;
    return next.buildUrl(original);
  }

  void reportSuccess([String? sourceId]) {
    final id = sourceId ?? _lastSourceId;
    if (id != null) _sourceById(id)?.recordSuccess();
  }

  void reportFailure([String? sourceId]) {
    final id = sourceId ?? _lastSourceId;
    if (id != null) _sourceById(id)?.recordFailure();
  }

  void setPreferred(String? sourceId) {
    _preferredSourceId = sourceId;
  }

  MirrorSource? _sourceById(String id) =>
      _sources.where((source) => source.id == id).firstOrNull;
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

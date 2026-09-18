import '../config/mirror_source.dart';
import 'article_url.dart';

/// Resolves a canonical article URL to a mirror-proxied URL and tracks the
/// health of each backend so the reader can fail over gracefully.
class ArticleResolver {
  ArticleResolver({List<MirrorSource>? sources})
    : _sources = sources ?? List.of(MirrorCatalog.defaults);

  final List<MirrorSource> _sources;
  String? _preferredSourceId;
  bool autoFallback = true;
  String? _lastOriginalUrl;
  String? _lastSourceId;

  List<MirrorSource> get sources => List.unmodifiable(_sources);
  String? get lastOriginalUrl => _lastOriginalUrl;
  String? get lastSourceId => _lastSourceId;
  String? get preferredSourceId => _preferredSourceId;

  /// Backends listed in the order they will be attempted.
  List<MirrorSource> get candidates {
    final ordered = List<MirrorSource>.from(_sources);
    if (_preferredSourceId != null) {
      ordered.sort((a, b) {
        if (a.id == _preferredSourceId) return -1;
        if (b.id == _preferredSourceId) return 1;
        return 0;
      });
    }
    return ordered;
  }

  /// All mirror-proxied URLs for a canonical article URL, healthy first.
  List<String> proxiedUrls(String originalUrl) {
    _lastOriginalUrl = ArticleUrl.canonicalize(originalUrl);
    final healthy = candidates
        .where((s) => s.available)
        .map((s) => s.buildUrl(_lastOriginalUrl!));
    final others = candidates
        .where((s) => !s.available)
        .map((s) => s.buildUrl(_lastOriginalUrl!));
    return [...healthy, ...others];
  }

  /// Best candidate now, or null when every mirror is marked unavailable.
  String? resolve(String originalUrl) {
    final urls = proxiedUrls(originalUrl);
    if (urls.isEmpty) return null;
    _lastSourceId = candidates.firstWhere((s) => s.available).id;
    return urls.first;
  }

  /// The next mirror to try for the same article when the current one fails.
  ///
  /// Returns null when automatic fallback is disabled so the chosen source is
  /// respected; the controller surfaces the error state instead.
  String? nextFallback() {
    if (!autoFallback) return null;
    final original = ArticleUrl.canonicalize(_lastOriginalUrl ?? '');
    if (original.isEmpty) return null;
    final healthy = candidates.where((s) => s.available).toList();
    if (healthy.isEmpty) {
      for (final s in _sources) {
        s.resetHealth();
      }
      healthy.addAll(candidates);
    }
    final fallback = healthy.firstWhere(
      (s) => s.id != _lastSourceId,
      orElse: () => healthy.first,
    );
    _lastSourceId = fallback.id;
    return fallback.buildUrl(original);
  }

  void reportSuccess(String sourceId) {
    final source = _sources.where((s) => s.id == sourceId).firstOrNull;
    source?.recordSuccess();
  }

  void reportFailure(String sourceId) {
    final source = _sources.where((s) => s.id == sourceId).firstOrNull;
    source?.recordFailure();
  }

  void setPreferred(String? sourceId) {
    _preferredSourceId = sourceId;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

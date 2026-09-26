/// How far the reader has got through one article.
///
/// Two positions are kept because either can be the better one to restore: the
/// absolute [offset] is exact but only valid while the article renders to the
/// same height, whereas [ratio] survives a font-size or theme change that
/// reflows the text.
class ReadingProgress {
  const ReadingProgress({
    required this.url,
    this.ratio = 0,
    this.offset = 0,
    this.startedAt,
    this.updatedAt,
  });

  /// Canonical URL of the article.
  final String url;

  /// Fraction of the scrollable distance covered, in `0..1`.
  final double ratio;

  /// Absolute scroll offset in CSS pixels.
  final double offset;

  /// When the article was first opened.
  final DateTime? startedAt;

  /// When the reader last moved through it.
  final DateTime? updatedAt;

  /// Below this the reader has barely moved, so the article counts as unopened
  /// and never shows up in "Continue reading".
  static const double kStartedThreshold = 0.02;

  /// At or above this the article counts as read.
  static const double kFinishedThreshold = 0.98;

  bool get isStarted => ratio > kStartedThreshold;

  bool get isFinished => ratio >= kFinishedThreshold;

  /// A finished article is still tracked, but it is not something to continue.
  bool get isResumable => isStarted && !isFinished;

  ReadingProgress copyWith({
    double? ratio,
    double? offset,
    DateTime? startedAt,
    DateTime? updatedAt,
  }) {
    return ReadingProgress(
      url: url,
      ratio: ratio ?? this.ratio,
      offset: offset ?? this.offset,
      startedAt: startedAt ?? this.startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

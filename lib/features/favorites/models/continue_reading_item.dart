/// An unfinished article the reader can pick up where they left off.
///
/// Pairs the stored position with the article's metadata, so the library can
/// show something recognisable without opening the article.
class ContinueReadingItem {
  const ContinueReadingItem({
    required this.url,
    required this.title,
    required this.ratio,
    this.author,
    this.domain,
    this.updatedAt,
  });

  /// Canonical URL of the article.
  final String url;

  /// Title from the metadata cache, or an empty string when the article has
  /// never been read far enough to record one.
  final String title;

  /// How far through the article the reader was, in `0..1`.
  final double ratio;

  final String? author;
  final String? domain;

  /// When the reader was last in this article.
  final DateTime? updatedAt;

  /// Progress as a whole percentage, for the bar and the label.
  int get percent => (ratio.clamp(0.0, 1.0) * 100).round();

  /// Title to show, with a readable stand-in for an article that has none.
  String get displayTitle => title.isNotEmpty ? title : 'Untitled article';
}

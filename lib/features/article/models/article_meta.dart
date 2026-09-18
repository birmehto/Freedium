/// Metadata extracted from a rendered article.
class ArticleMeta {
  const ArticleMeta({
    required this.title,
    this.author,
    this.publication,
    this.publishedAt,
    this.wordCount = 0,
  });

  factory ArticleMeta.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ArticleMeta(title: '');
    return ArticleMeta(
      title: json['title'] as String? ?? '',
      author: json['author'] as String?,
      publication: json['publication'] as String?,
      publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? ''),
      wordCount: (json['wordCount'] as num?)?.toInt() ?? 0,
    );
  }

  final String title;
  final String? author;
  final String? publication;
  final DateTime? publishedAt;
  final int wordCount;

  Map<String, dynamic> toJson() => {
    'title': title,
    'author': author,
    'publication': publication,
    'publishedAt': publishedAt?.toIso8601String(),
    'wordCount': wordCount,
  };

  /// Estimated reading time in whole minutes (≈200 wpm).
  int get readingTimeMinutes => (wordCount / 200).ceil();
}

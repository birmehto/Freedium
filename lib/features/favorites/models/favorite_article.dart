class FavoriteArticle {
  const FavoriteArticle({
    required this.title,
    required this.url,
    required this.visitedAt,
    this.author,
    this.domain,
    this.imageUrl,
  });

  factory FavoriteArticle.fromJson(Map<String, dynamic> json) {
    return FavoriteArticle(
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      visitedAt: DateTime.tryParse(json['visitedAt'] ?? '') ?? DateTime.now(),
      author: json['author'],
      domain: json['domain'],
      imageUrl: json['imageUrl'],
    );
  }

  final String title;
  final String url;
  final DateTime visitedAt;
  final String? author;
  final String? domain;
  final String? imageUrl;

  /// Returns a copy of this article with the given fields replaced.
  FavoriteArticle copyWith({
    String? title,
    String? url,
    DateTime? visitedAt,
    String? author,
    String? domain,
    String? imageUrl,
  }) {
    return FavoriteArticle(
      title: title ?? this.title,
      url: url ?? this.url,
      visitedAt: visitedAt ?? this.visitedAt,
      author: author ?? this.author,
      domain: domain ?? this.domain,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'visitedAt': visitedAt.toIso8601String(),
      'author': author,
      'domain': domain,
      'imageUrl': imageUrl,
    };
  }
}

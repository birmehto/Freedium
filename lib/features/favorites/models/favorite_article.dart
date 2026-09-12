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

/// An article saved for offline reading.
class SavedArticle {
  const SavedArticle({
    required this.title,
    required this.url,
    required this.html,
    this.author,
    this.publication,
    this.savedAt,
    this.imageCount = 0,
  });

  factory SavedArticle.fromJson(Map<String, dynamic> json) {
    return SavedArticle(
      title: json['title'] as String? ?? 'Saved article',
      url: json['url'] as String? ?? '',
      html: json['html'] as String? ?? '',
      author: json['author'] as String?,
      publication: json['publication'] as String?,
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? ''),
      imageCount: (json['imageCount'] as num?)?.toInt() ?? 0,
    );
  }

  final String title;
  final String url;
  final String html;
  final String? author;
  final String? publication;
  final DateTime? savedAt;
  final int imageCount;

  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
    'html': html,
    'author': author,
    'publication': publication,
    'savedAt': savedAt?.toIso8601String(),
    'imageCount': imageCount,
  };

  int get approximateBytes {
    final utf8 = html.codeUnits.length;
    final images = imageCount * 200 * 1024;
    return utf8 + images;
  }

  SavedArticle copyWith({
    String? title,
    String? url,
    String? html,
    String? author,
    String? publication,
    DateTime? savedAt,
    int? imageCount,
  }) {
    return SavedArticle(
      title: title ?? this.title,
      url: url ?? this.url,
      html: html ?? this.html,
      author: author ?? this.author,
      publication: publication ?? this.publication,
      savedAt: savedAt ?? this.savedAt,
      imageCount: imageCount ?? this.imageCount,
    );
  }
}

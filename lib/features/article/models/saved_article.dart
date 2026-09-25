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

  int get approximateBytes {
    final utf8 = html.codeUnits.length;
    final images = imageCount * 200 * 1024;
    return utf8 + images;
  }
}

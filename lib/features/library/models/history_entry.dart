/// A single entry in the reading-history list.
class HistoryEntry {
  const HistoryEntry({
    required this.title,
    required this.url,
    this.author,
    this.publication,
    this.openedAt,
    this.lastReadAt,
    this.progress = 0,
    this.completed = false,
    this.saved = false,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const HistoryEntry(title: '', url: '');
    return HistoryEntry(
      title: json['title'] as String? ?? 'Article',
      url: json['url'] as String? ?? '',
      author: json['author'] as String?,
      publication: json['publication'] as String?,
      openedAt: DateTime.tryParse(json['openedAt'] as String? ?? ''),
      lastReadAt: DateTime.tryParse(json['lastReadAt'] as String? ?? ''),
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      completed: json['completed'] as bool? ?? false,
      saved: json['saved'] as bool? ?? false,
    );
  }

  final String title;
  final String url;
  final String? author;
  final String? publication;
  final DateTime? openedAt;
  final DateTime? lastReadAt;
  final double progress;
  final bool completed;
  final bool saved;

  /// Relative time label e.g. "Today", "Yesterday", "This week", "Earlier".
  String get timeBucket {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(
      (lastReadAt ?? openedAt ?? now).year,
      (lastReadAt ?? openedAt ?? now).month,
      (lastReadAt ?? openedAt ?? now).day,
    );
    final diff = today.difference(day).inDays;
    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return 'This week';
    return 'Earlier';
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
    'author': author,
    'publication': publication,
    'openedAt': openedAt?.toIso8601String(),
    'lastReadAt': lastReadAt?.toIso8601String(),
    'progress': progress,
    'completed': completed,
    'saved': saved,
  };

  HistoryEntry copyWith({
    String? title,
    String? url,
    String? author,
    String? publication,
    DateTime? openedAt,
    DateTime? lastReadAt,
    double? progress,
    bool? completed,
    bool? saved,
  }) {
    return HistoryEntry(
      title: title ?? this.title,
      url: url ?? this.url,
      author: author ?? this.author,
      publication: publication ?? this.publication,
      openedAt: openedAt ?? this.openedAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      progress: progress ?? this.progress,
      completed: completed ?? this.completed,
      saved: saved ?? this.saved,
    );
  }
}

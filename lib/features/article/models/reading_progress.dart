/// Reading progress for a single article, keyed by its canonical URL.
class ReadingProgress {
  const ReadingProgress({
    this.progress = 0,
    this.scrollY = 0,
    this.startedAt,
    this.lastReadAt,
    this.completedAt,
  });

  factory ReadingProgress.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ReadingProgress();
    return ReadingProgress(
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      scrollY: (json['scrollY'] as num?)?.toDouble() ?? 0,
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? ''),
      lastReadAt: DateTime.tryParse(json['lastReadAt'] as String? ?? ''),
      completedAt: json['completedAt'] is String
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
    );
  }

  /// 0.0 → 1.0 fraction of the page scrolled.
  final double progress;

  /// Absolute scroll offset, restored when reopening in the reader.
  final double scrollY;

  final DateTime? startedAt;
  final DateTime? lastReadAt;

  /// Set once when the reader reaches ~bottom of the article.
  final DateTime? completedAt;

  bool get isCompleted => completedAt != null;

  Map<String, dynamic> toJson() => {
    'progress': progress,
    'scrollY': scrollY,
    'startedAt': startedAt?.toIso8601String(),
    'lastReadAt': lastReadAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  ReadingProgress copyWith({
    double? progress,
    double? scrollY,
    DateTime? startedAt,
    DateTime? lastReadAt,
    DateTime? completedAt,
    bool clearCompleted = false,
  }) {
    return ReadingProgress(
      progress: progress ?? this.progress,
      scrollY: scrollY ?? this.scrollY,
      startedAt: startedAt ?? this.startedAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      completedAt: clearCompleted ? null : (completedAt ?? this.completedAt),
    );
  }
}

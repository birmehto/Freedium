/// Categorized application error types.
///
/// These map onto the user-facing states the UI understands, so controllers
/// never have to reason about raw exceptions or status codes.
enum AppErrorType {
  network,
  timeout,
  invalidUrl,
  articleNotFound,
  mirrorUnavailable,
  parsing,
  storage,
  unknown,
}

/// Base class for every error surfaced through the application.
///
/// [message] is a short technical summary for logs, [userMessage] is a
/// friendly, human-readable copy that is safe to show in the UI, and [cause]
/// carries the original exception when one exists.
class AppException implements Exception {
  AppException({
    required this.type,
    required this.message,
    String? userMessage,
    this.cause,
  }) : userMessage = userMessage ?? defaultUserMessage(type);

  /// Maps a raw error to an [AppException], defaulting to [AppErrorType.unknown].
  factory AppException.from(Object error, {String? context}) {
    if (error is AppException) return error;
    final label = context == null ? '' : ' ($context)';
    return AppException(
      type: AppErrorType.unknown,
      message: 'Unexpected error$label',
      cause: error,
    );
  }

  /// Convenience factory for network failures.
  factory AppException.network([String? message, Object? cause]) =>
      AppException(
        type: AppErrorType.network,
        message: message ?? 'Network failure',
        cause: cause,
      );

  /// Convenience factory for timeouts.
  factory AppException.timeout([String? message, Object? cause]) =>
      AppException(
        type: AppErrorType.timeout,
        message: message ?? 'Operation timed out',
        cause: cause,
      );

  /// Convenience factory for invalid URLs.
  factory AppException.invalidUrl([String? message, Object? cause]) =>
      AppException(
        type: AppErrorType.invalidUrl,
        message: message ?? 'Invalid URL',
        cause: cause,
      );

  /// Convenience factory for missing articles.
  factory AppException.articleNotFound([String? message, Object? cause]) =>
      AppException(
        type: AppErrorType.articleNotFound,
        message: message ?? 'Article not found',
        cause: cause,
      );

  /// Convenience factory for unavailable mirrors.
  factory AppException.mirrorUnavailable([String? message, Object? cause]) =>
      AppException(
        type: AppErrorType.mirrorUnavailable,
        message: message ?? 'Mirror unavailable',
        cause: cause,
      );

  /// Convenience factory for parsing failures.
  factory AppException.parsing([String? message, Object? cause]) =>
      AppException(
        type: AppErrorType.parsing,
        message: message ?? 'Failed to parse content',
        cause: cause,
      );

  /// Convenience factory for storage failures.
  factory AppException.storage([String? message, Object? cause]) =>
      AppException(
        type: AppErrorType.storage,
        message: message ?? 'Storage failure',
        cause: cause,
      );

  /// The category of the failure.
  final AppErrorType type;

  /// Technical description, intended for logs.
  final String message;

  /// User-facing copy, safe to display in the UI.
  final String userMessage;

  /// The original exception/error that triggered this, when available.
  final Object? cause;

  /// The default user-facing copy for a given category.
  static String defaultUserMessage(AppErrorType type) {
    switch (type) {
      case AppErrorType.network:
        return 'Network error. Please check your internet connection.';
      case AppErrorType.timeout:
        return 'Request timed out. Please try again.';
      case AppErrorType.invalidUrl:
        return 'Please enter a valid URL.';
      case AppErrorType.articleNotFound:
        return 'Article not found. It may have been removed.';
      case AppErrorType.mirrorUnavailable:
        return 'The current source is unavailable. Please try again.';
      case AppErrorType.parsing:
        return 'The article could not be processed.';
      case AppErrorType.storage:
        return 'Could not save your data. Please try again.';
      case AppErrorType.unknown:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  String toString() => 'AppException($type): $message';
}

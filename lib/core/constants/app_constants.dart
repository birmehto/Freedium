/// App-wide constants that are not tied to a single feature.
abstract final class AppConstants {
  /// How long the reader waits before offering a retry.
  static const Duration webViewTimeout = Duration(seconds: 45);
}

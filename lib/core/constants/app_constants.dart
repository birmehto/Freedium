/// App-wide constants that are not tied to a single feature.
abstract final class AppConstants {
  /// How long the reader waits before offering a retry.
  static const Duration webViewTimeout = Duration(seconds: 45);

  /// Where the "buy me a coffee" support option sends the user.
  static const String supportUrl = 'https://buymeacoffee.com/birmehto';
}

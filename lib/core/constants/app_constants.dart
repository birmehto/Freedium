/// App-wide constants that are not tied to a single feature.
abstract final class AppConstants {
  /// How long the reader waits before offering a retry.
  static const Duration webViewTimeout = Duration(seconds: 45);

  /// Where the "buy me a coffee" support option sends the user.
  static const String supportUrl = 'https://buymeacoffee.com/birmehto';

  /// The Play Store package, used by the "Rate us" setting.
  static const String playStoreId = 'com.bir.freedium';

  /// Browser fallback when no Play Store app is installed (e.g. desktop).
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=$playStoreId';
}

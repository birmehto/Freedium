/// App-wide constants that are not tied to a single feature.
abstract final class AppConstants {
  /// How long the reader waits before offering a retry.
  static const Duration webViewTimeout = Duration(seconds: 45);

  /// How often the reader's scroll diagnostics are written while scrolling.
  ///
  /// A drag emits hundreds of `onScrollChanged` callbacks a second, so an
  /// unthrottled log would itself become the jank it is trying to measure.
  static const Duration scrollDiagnosticsInterval = Duration(seconds: 1);

  /// Whether the reader's scroll diagnostics are emitted in release builds too.
  ///
  /// Left on while the reader is being diagnosed — a WebView that refuses to
  /// scroll is invisible from the app's own UI, so these records are often the
  /// only evidence of what the document and the native view were doing. Turn it
  /// off before shipping.
  static const bool scrollDiagnosticsInRelease = true;
}

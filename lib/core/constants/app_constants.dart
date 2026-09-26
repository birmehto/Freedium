/// App-wide constants that are not tied to a single feature.
abstract final class AppConstants {
  /// How long the reader waits before offering a retry.
  static const Duration webViewTimeout = Duration(seconds: 45);

  /// How long the reader must stop scrolling before the position is measured
  /// and stored.
  ///
  /// Scrolling fires continuously, and measuring costs a round trip into the
  /// document, so the burst is collapsed into a single write once it settles.
  static const Duration scrollSettleDelay = Duration(milliseconds: 400);
}

/// Google Mobile Ads identifiers.
///
/// The unit below is Google's public **test** rewarded-video unit, which serves
/// test ads on any build. Swap it — and the matching application id in
/// `android/app/src/main/AndroidManifest.xml` — for the app's own AdMob unit
/// before publishing: serving a release build with a test unit is against AdMob
/// policy and earns nothing.
abstract final class AdConfig {
  /// Rewarded-video unit presented by the "support Freedium" flow.
  static const String rewardedUnitId = 'ca-app-pub-3940256099942544/5224354917';
}

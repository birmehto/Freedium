import 'package:envied/envied.dart';

part 'env.g.dart';

/// AdMob identifiers, read from a git-ignored `.env`.
///
/// Values are obfuscated into `env.g.dart` at build time (run
/// `dart run build_runner build`), which is also git-ignored, so real ids never
/// reach version control. When `.env` is absent — a fresh clone or CI — the
/// generator falls back to Google's public test ids, so the app still builds
/// and serves test ads. `.env.example` documents the keys.
///
/// The Android build reads the same file: `ADMOB_APP_ID` is injected into the
/// manifest as the `admobAppId` placeholder by `android/app/build.gradle.kts`.
@Envied(path: '.env')
abstract class AdEnv {
  /// Rewarded-video unit presented by the "support Freedium" flow.
  @EnviedField(
    varName: 'REWARDED_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917',
    obfuscate: true,
  )
  static final String rewardedUnitId = _AdEnv.rewardedUnitId;

  /// Google Mobile Ads application id.
  ///
  /// The Android build injects this into the manifest from `.env`; the Dart
  /// value is kept here so the whole secret has a single, documented home.
  @EnviedField(
    varName: 'ADMOB_APP_ID',
    defaultValue: 'ca-app-pub-3940256099942544~3347511713',
    obfuscate: true,
  )
  static final String admobAppId = _AdEnv.admobAppId;
}

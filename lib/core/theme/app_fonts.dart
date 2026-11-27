import 'package:google_fonts/google_fonts.dart';

/// Keeps the app's typography entirely offline.
///
/// Every weight the theme uses is bundled under `assets/fonts/` with the exact
/// `<Family>-<Variant>.ttf` names `google_fonts` looks for. With runtime
/// fetching disabled, a missing file is a build-time problem, not a silent
/// request to `fonts.gstatic.com` on a reader's device.
abstract final class AppFonts {
  static void configure() {
    GoogleFonts.config.allowRuntimeFetching = false;
  }
}

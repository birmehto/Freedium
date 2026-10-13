import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/utils/app_log.dart';
import '../../../core/widgets/app_snackbar.dart';

/// Drives the "support Freedium" options: watching a rewarded ad, or opening
/// the donation page.
///
/// Owns the ad interaction and the donation hand-off, and reports how an ad
/// attempt went — including the platform with no ad SDK, which simply reports
/// [RewardedAdOutcome.unavailable] — so the view can present the result.
class SupportController extends GetxController {
  SupportController(AdService ads) : _ads = ads;

  final AdService _ads;

  /// Whether a rewarded video is loaded and can be shown right now.
  bool get adReady => _ads.isReady.value;

  /// Whether an ad is on its way, so the dialog can show progress.
  bool get adLoading => _ads.isLoading.value;

  /// Why the last request produced no ad, for the view to explain after
  /// [watchAd] completes with [RewardedAdOutcome.unavailable].
  AdFailureReason get adFailureReason => _ads.lastFailureReason;

  /// Plays a rewarded video, completing with how the attempt ended so the
  /// caller can thank the user or explain why nothing played.
  Future<RewardedAdOutcome> watchAd() => _ads.showRewarded();

  /// Opens the donation page in the browser.
  Future<void> buyCoffee() async {
    final uri = Uri.parse(AppConstants.supportUrl);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (error) {
      final exception = AppException.from(error, context: 'buyCoffee');
      appLog(exception.toString(), name: 'Support', level: LogLevel.warning);
    }

    AppSnackbar.show(Get.context, message: 'Could not open the support page');
  }
}

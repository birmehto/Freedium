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
/// Owns the outcome handling (including the platform without an ad SDK) so the
/// view only has to say *what* was chosen, never how to present an ad or a link.
class SupportController extends GetxController {
  SupportController(AdService ads) : _ads = ads;

  final AdService _ads;

  /// Whether a rewarded video is loaded and can be shown right now.
  bool get adReady => _ads.isReady.value;

  /// Plays a rewarded video and reports the result to the user.
  Future<void> watchAd() async {
    final outcome = await _ads.showRewarded();

    switch (outcome) {
      case RewardedAdOutcome.earnedReward:
        _showMessage('Thank you for supporting Freedium!');
      case RewardedAdOutcome.unavailable:
        _showMessage('No ad is ready right now. Please try again in a moment.');
      case RewardedAdOutcome.dismissed:
        // Closed early: nothing earned, and nothing worth saying.
        break;
    }
  }

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

    _showMessage('Could not open the support page');
  }

  void _showMessage(String message) {
    AppSnackbar.show(Get.context, message: message);
  }
}

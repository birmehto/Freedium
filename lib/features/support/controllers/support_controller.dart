import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/app_log.dart';
import '../../../core/widgets/app_snackbar.dart';

/// Drives the "support Freedium" option: opening the donation page.
class SupportController extends GetxController {
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

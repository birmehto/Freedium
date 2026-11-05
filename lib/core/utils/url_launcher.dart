import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../errors/app_exception.dart';
import '../widgets/app_snackbar.dart';
import 'app_log.dart';

/// Opens [url] in the platform's external application.
///
/// Returns `true` when the URL was successfully handed off, `false` otherwise.
/// When [showFailureMessage] is set, a snackbar is shown on failure.
Future<bool> launchExternalUrl(
  String url, {
  bool showFailureMessage = true,
  String failureMessage = 'Could not open the link',
  String logName = 'UrlLauncher',
}) async {
  final uri = Uri.parse(url);

  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
  } catch (error) {
    final exception = AppException.from(error, context: 'launchExternalUrl');
    appLog(exception.toString(), name: logName, level: LogLevel.warning);
  }

  if (showFailureMessage) {
    AppSnackbar.show(Get.context, message: failureMessage);
  }
  return false;
}

/// Opens the Freedium support (donation) page.
Future<bool> launchSupportUrl() => launchExternalUrl(
  AppConstants.supportUrl,
  failureMessage: 'Could not open the support page',
  logName: 'Support',
);
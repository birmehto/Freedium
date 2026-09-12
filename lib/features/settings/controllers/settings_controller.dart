import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/theme_service.dart';
import '../../../core/utils/app_log.dart';

class SettingsController extends GetxController {
  final ThemeService _themeService = Get.find<ThemeService>();

  final appVersion = ''.obs;

  bool get isDarkMode => _themeService.isDarkMode.value;

  @override
  void onInit() {
    super.onInit();
    _loadAppVersion();
  }

  void toggleTheme(bool value) {
    _themeService.toggleTheme(value);
  }

  Future<void> sendFeedback() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'birmehto@gmail.com',
      queryParameters: {'subject': 'Readora Feedback'},
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion.value = info.version;
    } catch (e) {
      appLog('Failed to load app version: $e');
    }
  }
}

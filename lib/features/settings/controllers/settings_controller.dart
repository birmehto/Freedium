import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/storage_service.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/utils/app_log.dart';

class SettingsController extends GetxController {
  final ThemeService _themeService = Get.find();
  final StorageService _storage = Get.find();

  final appVersion = ''.obs;

  // Reader preferences
  final fontSize = 17.0.obs;

  bool get isDarkMode => _themeService.isDarkMode.value;

  @override
  void onInit() {
    super.onInit();
    _loadAppVersion();
    fontSize.value = _storage.fontSize;
  }

  void toggleTheme(bool value) {
    _themeService.toggleTheme(value);
  }

  void setFontSize(double size) {
    fontSize.value = size;
    _storage.fontSize = size;
  }

  Future<void> sendFeedback() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'birmehto@gmail.com',
      queryParameters: {'subject': 'Freedium Feedback'},
    );

    try {
      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        M3ESnackbar.show(
          // ignore: use_build_context_synchronously
          Get.context!,
          message: 'No email app found. Email us at birmehto@gmail.com',
        );
        return;
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      appLog('Failed to open email client: $e');
      M3ESnackbar.show(Get.context!, message: "Couldn't open email app");
    }
  }

  Future<void> openGitHub() async {
    await _openExternal('https://github.com/birmehto/Freedium');
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        M3ESnackbar.show(Get.context!, message: 'Could not open link');
        return;
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      appLog('Failed to open link: $e');
      M3ESnackbar.show(Get.context!, message: "Couldn't open link");
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

import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/storage_service.dart';
import '../../../../core/services/theme_service.dart';

class SettingsController extends GetxController {
  final StorageService _storage = Get.find();
  final ThemeService _themeService = Get.find();

  final activeEngineUrl = ''.obs;

  bool get isDarkMode => _themeService.isDarkMode.value;

  @override
  void onInit() {
    super.onInit();
    activeEngineUrl.value = _storage.activeEngineUrl;
  }

  void toggleTheme(bool value) {
    _themeService.toggleTheme(value);
  }

  void setEngineUrl(String url) {
    activeEngineUrl.value = url;
    _storage.activeEngineUrl = url;
  }

  Future<void> sendFeedback() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'birmehto@gmail.com',
      queryParameters: {'subject': 'Readora Feedback'},
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }
}

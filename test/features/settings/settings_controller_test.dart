import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:readora/core/services/storage_service.dart';
import 'package:readora/core/services/theme_service.dart';
import 'package:readora/features/settings/controllers/settings_controller.dart';

class MockStorageService extends StorageService {
  bool _isDarkMode = false;

  @override
  bool get isDarkMode => _isDarkMode;

  @override
  set isDarkMode(bool value) {
    _isDarkMode = value;
  }
}

class MockThemeService extends ThemeService {
  @override
  void onInit() {
    super.onInit();
    isDarkMode.value = Get.find<StorageService>().isDarkMode;
  }
}

void main() {
  late MockStorageService mockStorage;
  late SettingsController controller;

  setUp(() {
    Get.reset();
    mockStorage = MockStorageService();
    Get.put<StorageService>(mockStorage);
    Get.put<ThemeService>(MockThemeService());
    controller = SettingsController();
    controller.onInit();
  });

  group('SettingsController Tests', () {
    test('Initialization is reactive to stored theme state', () {
      mockStorage.isDarkMode = true;

      final themeService = Get.find<ThemeService>();
      themeService.isDarkMode.value = true;

      final freshController = SettingsController();

      expect(freshController.isDarkMode, true);
    });

    test('toggleTheme updates state and storage service', () {
      expect(controller.isDarkMode, false);
      expect(mockStorage.isDarkMode, false);

      controller.toggleTheme(true);

      expect(controller.isDarkMode, true);
      expect(mockStorage.isDarkMode, true);
    });
  });
}

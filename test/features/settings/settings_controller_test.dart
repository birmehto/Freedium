import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:readora/core/services/storage_service.dart';
import 'package:readora/core/services/theme_service.dart';
import 'package:readora/features/settings/presentation/controllers/settings_controller.dart';

class MockStorageService extends StorageService {
  bool _isDarkMode = false;
  String _activeEngineUrl = 'https://freedium.cfd/';

  @override
  bool get isDarkMode => _isDarkMode;

  @override
  set isDarkMode(bool value) {
    _isDarkMode = value;
  }

  @override
  String get activeEngineUrl => _activeEngineUrl;

  @override
  set activeEngineUrl(String value) {
    _activeEngineUrl = value;
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
    test('Initialization loads correct states from Storage', () {
      mockStorage.isDarkMode = true;
      mockStorage.activeEngineUrl = 'https://readmedium.com/';

      final themeService = Get.find<ThemeService>();
      themeService.isDarkMode.value = true;

      final freshController = SettingsController();
      freshController.onInit();

      expect(freshController.isDarkMode, true);
      expect(freshController.activeEngineUrl.value, 'https://readmedium.com/');
    });

    test('toggleTheme updates state and storage service', () {
      expect(controller.isDarkMode, false);
      expect(mockStorage.isDarkMode, false);

      controller.toggleTheme(true);

      expect(controller.isDarkMode, true);
      expect(mockStorage.isDarkMode, true);
    });

    test('setEngineUrl updates state and storage service', () {
      expect(controller.activeEngineUrl.value, 'https://freedium.cfd/');
      expect(mockStorage.activeEngineUrl, 'https://freedium.cfd/');

      controller.setEngineUrl('https://readmedium.com/');

      expect(controller.activeEngineUrl.value, 'https://readmedium.com/');
      expect(mockStorage.activeEngineUrl, 'https://readmedium.com/');
    });
  });
}

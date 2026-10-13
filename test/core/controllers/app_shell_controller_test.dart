import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/controllers/app_shell_controller.dart';
import 'package:freedium/core/services/storage_service.dart';
import 'package:freedium/features/favorites/controllers/favorites_controller.dart';
import 'package:freedium/features/settings/controllers/settings_controller.dart';
import 'package:freedium/features/settings/models/reader_settings.dart';
import 'package:get/get.dart';

import '../../helpers/test_env.dart';

void main() {
  late AppShellController shell;
  late FavoritesController favorites;
  late SettingsController settings;
  late StorageService storage;

  setUp(() {
    final services = registerServices();
    storage = services.storage;

    favorites = FavoritesController(storage)..onInit();
    settings = SettingsController(services.theme, storage)..onInit();
    Get.put<FavoritesController>(favorites);
    Get.put<SettingsController>(settings);

    shell = AppShellController();
  });

  tearDown(Get.reset);

  group('AppShellController', () {
    test('starts on Home', () {
      expect(shell.tab.value, AppShellTab.home);
      expect(shell.tab.value.index, 0);
    });

    test('selectTab switches the visible tab', () {
      shell.selectTab(AppShellTab.library);
      expect(shell.tab.value, AppShellTab.library);

      shell.selectTab(AppShellTab.settings);
      expect(shell.tab.value, AppShellTab.settings);

      shell.selectTab(AppShellTab.home);
      expect(shell.tab.value, AppShellTab.home);
    });

    test('opening Settings re-reads the stored reader settings', () {
      storage.preferences.readerSettings = const ReaderSettings(fontSize: 21);

      shell.selectTab(AppShellTab.settings);

      expect(settings.readerSettings.value.fontSize, 21);
    });

    test('Home has nothing to refresh', () {
      settings.readerSettings.value = const ReaderSettings(fontSize: 9);

      shell.selectTab(AppShellTab.home);

      expect(settings.readerSettings.value.fontSize, 9);
    });

    test('an unregistered tab controller is not looked up', () {
      // Tabs are bound lazily, so the shell must survive one that never ran.
      Get.delete<FavoritesController>();

      expect(() => shell.selectTab(AppShellTab.library), returnsNormally);
    });
  });
}

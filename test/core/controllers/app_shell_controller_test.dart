import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/controllers/app_shell_controller.dart';
import 'package:freedium/core/services/storage_service.dart';
import 'package:freedium/features/favorites/controllers/favorites_controller.dart';
import 'package:freedium/features/settings/controllers/settings_controller.dart';
import 'package:freedium/features/settings/models/reader_settings.dart';
import 'package:get/get.dart';

import '../../helpers/test_env.dart';

const _articleUrl = 'https://medium.com/@someone/an-article';

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

    test(
      'opening Library picks up a position stored while it was hidden',
      () async {
        // Every tab stays mounted, so a position written by the reader is only
        // visible once the library has re-read it.
        await storage.progress.save(_articleUrl, ratio: 0.5);
        expect(favorites.continueReading, isEmpty);

        shell.selectTab(AppShellTab.library);
        await pumpEventQueue();

        expect(favorites.continueReading, hasLength(1));
        expect(favorites.continueReading.single.url, _articleUrl);
      },
    );

    test('re-opening the visible tab refreshes it again', () async {
      shell.selectTab(AppShellTab.library);
      await storage.progress.save(_articleUrl, ratio: 0.5);
      shell.selectTab(AppShellTab.library);
      await pumpEventQueue();

      expect(favorites.continueReading, hasLength(1));
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

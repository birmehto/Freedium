import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/controllers/app_controllers.dart';
import 'package:freedium/core/controllers/app_shell_controller.dart';
import 'package:freedium/core/services/storage_service.dart';
import 'package:freedium/features/settings/models/reader_settings.dart';

import '../../helpers/test_env.dart';

void main() {
  late ProviderContainer container;
  late AppShellController shell;
  late StorageService storage;

  setUp(() {
    final services = registerServices();
    container = services.container;
    storage = services.storage;

    shell = container.read(appShellTabProvider.notifier);
  });

  // The container is per-test and short-lived. It is deliberately not disposed
  // here: readerSettingsProvider's onDispose writes through ref, which Riverpod
  // forbids during a dispose callback in debug mode.

  AppShellTab currentTab() => container.read(appShellTabProvider);

  group('AppShellController', () {
    test('starts on Home', () {
      expect(currentTab(), AppShellTab.home);
      expect(currentTab().index, 0);
    });

    test('selectTab switches the visible tab', () {
      shell.selectTab(AppShellTab.library);
      expect(currentTab(), AppShellTab.library);

      shell.selectTab(AppShellTab.settings);
      expect(currentTab(), AppShellTab.settings);

      shell.selectTab(AppShellTab.home);
      expect(currentTab(), AppShellTab.home);
    });

    test('opening Settings re-reads the stored reader settings', () {
      storage.preferences.readerSettings = const ReaderSettings(fontSize: 21);

      shell.selectTab(AppShellTab.settings);

      // Riverpod builds the reader settings provider lazily, so its first read
      // after switching to Settings observes the value stored on disk.
      expect(container.read(readerSettingsProvider).fontSize, 21);
    });

    test('Home has nothing to refresh', () {
      container
          .read(readerSettingsProvider.notifier)
          .update(const ReaderSettings(fontSize: 9));

      shell.selectTab(AppShellTab.home);

      expect(container.read(readerSettingsProvider).fontSize, 9);
    });

    test('an unregistered tab controller is not looked up', () {
      // Tabs are bound lazily in Riverpod, so the shell must survive one that
      // never had its controller read.
      expect(() => shell.selectTab(AppShellTab.library), returnsNormally);
      expect(currentTab(), AppShellTab.library);
    });
  });
}

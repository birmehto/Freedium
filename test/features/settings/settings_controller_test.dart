import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/controllers/app_controllers.dart';
import 'package:freedium/core/services/storage_service.dart';
import 'package:freedium/core/storage/preferences_store.dart';
import 'package:freedium/features/settings/controllers/settings_controller.dart';
import 'package:freedium/features/settings/models/reader_settings.dart';
import 'package:freedium/features/settings/models/reader_theme_mode.dart';

import '../../helpers/test_env.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late SettingsController controller;
  late StorageService storage;

  setUp(() {
    final services = registerServices();
    container = services.container;
    storage = services.storage;
    controller = container.read(settingsControllerProvider.notifier);
  });

  // The container is per-test and short-lived. It is deliberately not disposed
  // here: readerSettingsProvider's onDispose writes through ref, which Riverpod
  // forbids during a dispose callback in debug mode.

  group('SettingsController', () {
    test('initializes from stored preferences', () {
      final state = container.read(settingsControllerProvider);
      expect(state.themeMode, isNotEmpty);
      expect(container.read(readerSettingsProvider).fontSize, 17);
      expect(state.preferredMirror, isNull);
      expect(state.autoFallback, isTrue);
    });

    test('reflects a stored theme preference', () {
      final fresh = registerServices(
        seed: {PreferencesStore.themeModeKey: PreferencesStore.modeDark},
      );
      addTearDown(fresh.container.dispose);

      expect(fresh.container.read(themeControllerProvider).isDarkMode, isTrue);
    });

    test('setThemeMode updates state and storage', () {
      controller.setThemeMode(PreferencesStore.modeDark);

      expect(
        container.read(settingsControllerProvider).themeMode,
        PreferencesStore.modeDark,
      );
      expect(storage.preferences.themeMode, PreferencesStore.modeDark);
    });

    test('toggleTheme flips the mode', () {
      controller.toggleTheme(true);
      expect(container.read(themeControllerProvider).isDarkMode, isTrue);

      controller.toggleTheme(false);
      expect(container.read(themeControllerProvider).isDarkMode, isFalse);
    });

    test('setFontSize persists the reader default', () {
      final reader = container.read(readerSettingsProvider.notifier);
      reader.setFontSize(22);

      expect(container.read(readerSettingsProvider).fontSize, 22);
      // Font-size writes are debounced; flush to assert the stored default.
      reader.flush();
      expect(storage.preferences.readerSettings.fontSize, 22);
    });

    test('setFontSize clamps to the supported range', () {
      final reader = container.read(readerSettingsProvider.notifier);
      reader.setFontSize(999);
      expect(
        container.read(readerSettingsProvider).fontSize,
        ReaderSettings.kMaxFontSize,
      );

      reader.setFontSize(1);
      expect(
        container.read(readerSettingsProvider).fontSize,
        ReaderSettings.kMinFontSize,
      );
    });

    test('updateReaderSettings stores the whole object', () {
      final reader = container.read(readerSettingsProvider.notifier);
      reader.update(
        const ReaderSettings(
          fontSize: 20,
          fontFamily: 'Georgia',
          themeMode: ReaderThemeMode.sepia,
        ),
      );
      reader.flush();

      final stored = storage.preferences.readerSettings;
      expect(stored.fontSize, 20);
      expect(stored.fontFamily, 'Georgia');
      expect(stored.themeMode, ReaderThemeMode.sepia);
    });

    test('setPreferredMirror persists a pinned mirror', () {
      controller.setPreferredMirror('textise');
      expect(storage.preferences.preferredMirror, 'textise');
      expect(
        container.read(settingsControllerProvider).preferredMirror,
        'textise',
      );

      controller.setPreferredMirror(null);
      expect(storage.preferences.preferredMirror, isNull);
    });

    test('setAutoFallback persists the choice', () {
      controller.setAutoFallback(false);

      expect(container.read(settingsControllerProvider).autoFallback, isFalse);
      expect(storage.preferences.autoFallback, isFalse);
    });
  });

    test('rateApp opens the store without throwing', () async {
      // No platform channel is mocked here; the launcher failure is handled
      // and reported through the snackbar rather than escaping the controller.
      await expectLater(controller.rateApp(), completes);
    });
}

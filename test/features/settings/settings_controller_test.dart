import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/services/storage_service.dart';
import 'package:freedium/core/storage/preferences_store.dart';
import 'package:freedium/features/settings/controllers/settings_controller.dart';
import 'package:freedium/features/settings/models/reader_settings.dart';
import 'package:freedium/features/settings/models/reader_theme_mode.dart';

import '../../helpers/test_env.dart';

void main() {
  late SettingsController controller;
  late StorageService storage;

  setUp(() {
    final services = registerServices();
    storage = services.storage;
    controller = SettingsController(services.theme, services.storage);
    controller.onInit();
  });

  group('SettingsController', () {
    test('initializes from stored preferences', () {
      expect(controller.themeMode.value, isNotEmpty);
      expect(controller.readerSettings.value.fontSize, 17);
      expect(controller.preferredMirror.value, isNull);
      expect(controller.autoFallback.value, isTrue);
    });

    test('reflects a stored theme preference', () {
      final fresh = registerServices(
        seed: {PreferencesStore.themeModeKey: PreferencesStore.modeDark},
      );
      final other = SettingsController(fresh.theme, fresh.storage)..onInit();

      expect(other.isDarkMode, isTrue);
    });

    test('setThemeMode updates state and storage', () {
      controller.setThemeMode(PreferencesStore.modeDark);

      expect(controller.themeMode.value, PreferencesStore.modeDark);
      expect(storage.preferences.themeMode, PreferencesStore.modeDark);
    });

    test('toggleTheme flips the mode', () {
      controller.toggleTheme(true);
      expect(controller.isDarkMode, isTrue);

      controller.toggleTheme(false);
      expect(controller.isDarkMode, isFalse);
    });

    test('setFontSize persists the reader default', () {
      controller.setFontSize(22);

      expect(controller.fontSize, 22);
      expect(controller.readerSettings.value.fontSize, 22);
      expect(storage.preferences.readerSettings.fontSize, 22);
    });

    test('setFontSize clamps to the supported range', () {
      controller.setFontSize(999);
      expect(controller.fontSize, ReaderSettings.kMaxFontSize);

      controller.setFontSize(1);
      expect(controller.fontSize, ReaderSettings.kMinFontSize);
    });

    test('updateReaderSettings stores the whole object', () {
      controller.updateReaderSettings(
        const ReaderSettings(
          fontSize: 20,
          fontFamily: 'Georgia',
          themeMode: ReaderThemeMode.sepia,
        ),
      );

      final stored = storage.preferences.readerSettings;
      expect(stored.fontSize, 20);
      expect(stored.fontFamily, 'Georgia');
      expect(stored.themeMode, ReaderThemeMode.sepia);
    });

    test('setPreferredMirror persists a pinned mirror', () {
      controller.setPreferredMirror('textise');
      expect(storage.preferences.preferredMirror, 'textise');

      controller.setPreferredMirror(null);
      expect(storage.preferences.preferredMirror, isNull);
    });

    test('setAutoFallback persists the choice', () {
      controller.setAutoFallback(false);

      expect(controller.autoFallback.value, isFalse);
      expect(storage.preferences.autoFallback, isFalse);
    });
  });
}

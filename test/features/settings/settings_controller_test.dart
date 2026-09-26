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

  group('offline articles', () {
    test('reports an empty cache', () {
      expect(controller.hasOfflineArticles, isFalse);
      expect(controller.offlineSummary, '0 articles • Empty');
    });

    test('counts what is cached', () async {
      await storage.cache.save(url: 'https://medium.com/a', html: '<p>a</p>');
      await storage.cache.save(url: 'https://medium.com/b', html: '<p>b</p>');

      expect(controller.hasOfflineArticles, isTrue);
      expect(controller.offlineSummary, startsWith('2 articles • '));
      expect(controller.cachedArticles.value, 2);
    });

    test('uses the singular for one article', () async {
      await storage.cache.save(url: 'https://medium.com/a', html: '<p>a</p>');

      expect(controller.offlineSummary, startsWith('1 article • '));
    });

    test('clearOfflineArticles empties the cache', () async {
      await storage.cache.save(url: 'https://medium.com/a', html: '<p>a</p>');

      await controller.clearOfflineArticles();

      expect(controller.hasOfflineArticles, isFalse);
      expect(await storage.cache.contains('https://medium.com/a'), isFalse);
    });

    test('a second clear while one is running is ignored', () async {
      await storage.cache.save(url: 'https://medium.com/a', html: '<p>a</p>');

      await Future.wait([
        controller.clearOfflineArticles(),
        controller.clearOfflineArticles(),
      ]);

      expect(controller.hasOfflineArticles, isFalse);
      expect(controller.isClearingCache.value, isFalse);
    });

    test('the busy state is visible while clearing', () async {
      await storage.cache.save(url: 'https://medium.com/a', html: '<p>a</p>');

      final clearing = controller.clearOfflineArticles();
      expect(controller.isClearingCache.value, isTrue);

      await clearing;
      expect(controller.isClearingCache.value, isFalse);
    });

    test('clearing the cache leaves reading progress alone', () async {
      await storage.cache.save(url: 'https://medium.com/a', html: '<p>a</p>');
      await storage.progress.save('https://medium.com/a', ratio: 0.4);

      await controller.clearOfflineArticles();

      expect(
        await storage.progress.progressFor('https://medium.com/a'),
        isNotNull,
      );
    });
  });
}

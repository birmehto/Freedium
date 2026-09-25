import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/services/theme_service.dart';
import 'package:freedium/core/storage/preferences_store.dart';
import 'package:get/get.dart';

import '../../helpers/test_env.dart';

void main() {
  setUp(Get.reset);

  test('starts in the stored theme mode', () {
    final storage = createTestStorage();
    final theme = ThemeService(storage.preferences);
    theme.onInit();

    expect(theme.preferredMode, PreferencesStore.modeSystem);
    expect(theme.themeMode, ThemeMode.system);
  });

  test('reads a persisted dark preference', () {
    final storage = createTestStorage(
      seed: {PreferencesStore.themeModeKey: PreferencesStore.modeDark},
    );
    final theme = ThemeService(storage.preferences);
    theme.onInit();

    expect(theme.isDarkMode.value, isTrue);
    expect(theme.themeMode, ThemeMode.dark);
  });

  test('migrates a pre-1.0 boolean theme value', () {
    final storage = createTestStorage(
      seed: {PreferencesStore.themeModeKey: true},
    );
    final theme = ThemeService(storage.preferences);
    theme.onInit();

    expect(theme.preferredMode, PreferencesStore.modeDark);
  });

  test('toggleTheme flips the mode and persists it', () {
    final storage = createTestStorage();
    final theme = ThemeService(storage.preferences);
    theme.onInit();

    theme.toggleTheme(true);
    expect(theme.isDarkMode.value, isTrue);
    expect(theme.themeMode, ThemeMode.dark);
    expect(storage.preferences.themeMode, PreferencesStore.modeDark);

    theme.toggleDarkMode();
    expect(theme.isDarkMode.value, isFalse);
    expect(theme.themeMode, ThemeMode.light);
    expect(storage.preferences.themeMode, PreferencesStore.modeLight);
  });

  test('setThemeMode keeps light and dark explicit', () {
    final storage = createTestStorage();
    final theme = ThemeService(storage.preferences);
    theme.onInit();

    theme.setThemeMode(PreferencesStore.modeSystem);
    expect(theme.themeMode, ThemeMode.system);

    theme.setThemeMode(PreferencesStore.modeLight);
    expect(theme.themeMode, ThemeMode.light);
  });
}

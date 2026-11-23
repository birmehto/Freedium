import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/controllers/app_controllers.dart';
import 'package:freedium/core/services/storage_service.dart';
import 'package:freedium/core/storage/preferences_store.dart';
import 'package:freedium/core/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/test_env.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late StorageService storage;

  setUp(() {
    final services = registerServices();
    container = services.container;
    storage = services.storage;
  });

  tearDown(() => container.dispose());

  ThemeMode resolvedThemeMode() => AppTheme.themeMode(
    container.read(themeControllerProvider).preferredMode,
  );

  test('starts in the stored theme mode', () {
    final theme = container.read(themeControllerProvider);

    expect(theme.preferredMode, PreferencesStore.modeSystem);
    expect(resolvedThemeMode(), ThemeMode.system);
  });

  test('reads a persisted dark preference', () {
    final services = registerServices(
      seed: {PreferencesStore.themeModeKey: PreferencesStore.modeDark},
    );
    addTearDown(services.container.dispose);

    final theme = services.container.read(themeControllerProvider);
    expect(theme.isDarkMode, isTrue);
    expect(
      AppTheme.themeMode(theme.preferredMode),
      ThemeMode.dark,
    );
  });

  test('migrates a pre-1.0 boolean theme value', () {
    final services = registerServices(
      seed: {PreferencesStore.themeModeKey: true},
    );
    addTearDown(services.container.dispose);

    expect(
      services.container.read(themeControllerProvider).preferredMode,
      PreferencesStore.modeDark,
    );
  });

  test('toggleTheme flips the mode and persists it', () {
    final theme = container.read(themeControllerProvider.notifier);

    theme.toggleTheme(true);
    expect(container.read(themeControllerProvider).isDarkMode, isTrue);
    expect(resolvedThemeMode(), ThemeMode.dark);
    expect(storage.preferences.themeMode, PreferencesStore.modeDark);

    theme.toggleDarkMode();
    expect(container.read(themeControllerProvider).isDarkMode, isFalse);
    expect(resolvedThemeMode(), ThemeMode.light);
    expect(storage.preferences.themeMode, PreferencesStore.modeLight);
  });

  test('setThemeMode keeps light and dark explicit', () {
    final theme = container.read(themeControllerProvider.notifier);

    theme.setThemeMode(PreferencesStore.modeSystem);
    expect(resolvedThemeMode(), ThemeMode.system);

    theme.setThemeMode(PreferencesStore.modeLight);
    expect(resolvedThemeMode(), ThemeMode.light);
  });
}

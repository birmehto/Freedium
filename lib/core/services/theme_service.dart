import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart'
    show WidgetsBinding, WidgetsBindingObserver;
import 'package:get/get.dart';

import '../storage/preferences_store.dart';

/// Owns the app theme mode and keeps it in sync with the OS setting.
///
/// Injected with a [PreferencesStore] rather than reaching for a global, so the
/// service is testable and its dependency is explicit.
class ThemeService extends GetxService with WidgetsBindingObserver {
  ThemeService(this._preferences);

  final PreferencesStore _preferences;

  /// Effective dark/light state, resolving `system` against the platform.
  final isDarkMode = true.obs;

  @override
  void onInit() {
    super.onInit();
    isDarkMode.value = _preferences.isDarkMode;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangePlatformBrightness() {
    if (preferredMode != PreferencesStore.modeSystem) return;
    isDarkMode.value = _preferences.isDarkMode;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// Full app theme mode, including [ThemeMode.system].
  ThemeMode get themeMode => switch (preferredMode) {
    PreferencesStore.modeLight => ThemeMode.light,
    PreferencesStore.modeDark => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  /// The `system` / `light` / `dark` preference backed by storage.
  String get preferredMode => _preferences.themeMode;

  void setThemeMode(String mode) {
    _preferences.themeMode = mode;
    _sync();
  }

  void toggleTheme(bool dark) {
    setThemeMode(dark ? PreferencesStore.modeDark : PreferencesStore.modeLight);
  }

  void toggleDarkMode() => toggleTheme(!isDarkMode.value);

  void _sync() {
    isDarkMode.value = _preferences.isDarkMode;
    Get.changeThemeMode(themeMode);
  }
}

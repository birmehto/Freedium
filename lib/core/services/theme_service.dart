import 'package:flutter/material.dart' show ThemeMode, WidgetsBinding;
import 'package:flutter/widgets.dart' show WidgetsBindingObserver;
import 'package:get/get.dart';

import 'storage_service.dart';

class ThemeService extends GetxService with WidgetsBindingObserver {
  final StorageService _storage = Get.find();

  final isDarkMode = true.obs;

  @override
  void onInit() {
    super.onInit();
    isDarkMode.value = _storage.isDarkMode;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangePlatformBrightness() {
    if (preferredMode != 'system') return;
    isDarkMode.value = _storage.isDarkMode;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// Full app theme mode, including `ThemeMode.system`.
  ThemeMode get themeMode {
    final mode = _storage.preferences.themeMode;
    return switch (mode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  /// The system/light/dark preference backed by storage.
  String get preferredMode => _storage.preferences.themeMode;

  void toggleTheme(bool value) {
    _storage.isDarkMode = value;
    _storage.preferences.themeMode = value ? 'dark' : 'light';
    isDarkMode.value = _storage.isDarkMode;
    Get.changeThemeMode(themeMode);
  }

  void setThemeMode(String mode) {
    _storage.preferences.themeMode = mode;
    isDarkMode.value = _storage.isDarkMode;
    Get.changeThemeMode(themeMode);
  }

  void toggleDarkMode() {
    toggleTheme(!isDarkMode.value);
  }
}

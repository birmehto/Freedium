import 'package:flutter/material.dart' show ThemeMode;
import 'package:get/get.dart';

import 'storage_service.dart';

class ThemeService extends GetxService {
  final StorageService _storage = Get.find();

  final isDarkMode = true.obs;

  @override
  void onInit() {
    super.onInit();
    isDarkMode.value = _storage.isDarkMode;
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

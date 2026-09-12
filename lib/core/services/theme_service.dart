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

  ThemeMode get themeMode =>
      isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme(bool value) {
    isDarkMode.value = value;
    _storage.isDarkMode = value;
    Get.changeThemeMode(themeMode);
  }

  void toggleDarkMode() {
    toggleTheme(!isDarkMode.value);
  }
}

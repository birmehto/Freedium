import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:readora/core/services/clipboard_service.dart';
import 'package:readora/core/services/share_intent_service.dart';
import 'package:readora/core/services/storage_service.dart';
import 'package:readora/core/services/theme_service.dart';

class MockStorageService extends StorageService {
  bool _dark = false;

  @override
  bool get isDarkMode => _dark;

  @override
  set isDarkMode(bool value) {
    _dark = value;
  }

  @override
  double get fontSize => 16.0;
  @override
  String get fontFamily => 'Inter';
  @override
  List<dynamic> get favorites => [];
}

class MockShareIntentService extends ShareIntentService {
  @override
  Future<ShareIntentService> init() async => this;
}

class MockClipboardService extends ClipboardService {}

class MockThemeService extends ThemeService {
  @override
  void onInit() {
    super.onInit();
    isDarkMode.value = Get.find<StorageService>().isDarkMode;
  }
}

void main() {
  setUp(() {
    Get.reset();
    Get.put<StorageService>(MockStorageService());
    Get.put<ThemeService>(MockThemeService());
    Get.put<ShareIntentService>(MockShareIntentService());
    Get.put<ClipboardService>(MockClipboardService());
  });

  test('ThemeService initializes from StorageService', () {
    final themeService = Get.find<ThemeService>();
    expect(themeService.isDarkMode.value, false);
    expect(themeService.themeMode, ThemeMode.light);
  });

  test('ThemeService toggles dark mode', () {
    final themeService = Get.find<ThemeService>();
    themeService.toggleTheme(true);
    expect(themeService.isDarkMode.value, true);
    expect(themeService.themeMode, ThemeMode.dark);

    themeService.toggleDarkMode();
    expect(themeService.isDarkMode.value, false);
    expect(themeService.themeMode, ThemeMode.light);
  });
}

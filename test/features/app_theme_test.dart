import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/app.dart';
import 'package:freedium/core/services/clipboard_service.dart';
import 'package:freedium/core/services/share_intent_service.dart';
import 'package:freedium/core/services/storage_service.dart';
import 'package:freedium/core/services/theme_service.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

class MockStorageService extends StorageService {
  bool _dark = false;

  @override
  bool get isDarkMode => _dark;

  @override
  set isDarkMode(bool value) {
    _dark = value;
  }

  @override
  double get fontSize => 17.0;

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
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    Get.put<StorageService>(MockStorageService());
    Get.put<ThemeService>(MockThemeService());
    Get.put<ShareIntentService>(MockShareIntentService());
    Get.put<ClipboardService>(MockClipboardService());
  });

  Brightness resolvedBrightness(WidgetTester tester) {
    final context = tester.element(find.byType(GetMaterialApp).first);
    return M3ETheme.brightnessOf(context);
  }

  testWidgets('theme service toggle switches the resolved M3E theme', (
    tester,
  ) async {
    final themeService = Get.find<ThemeService>();

    await tester.pumpWidget(const Freedium());
    await tester.pumpAndSettle();

    expect(resolvedBrightness(tester), Brightness.light);

    themeService.toggleTheme(true);
    await tester.pumpAndSettle();

    expect(resolvedBrightness(tester), Brightness.dark);

    themeService.toggleTheme(false);
    await tester.pumpAndSettle();

    expect(resolvedBrightness(tester), Brightness.light);
  });

  testWidgets('dark mode preference is applied on startup', (tester) async {
    Get.find<StorageService>().isDarkMode = true;
    Get.find<ThemeService>().isDarkMode.value = true;

    await tester.pumpWidget(const Freedium());
    await tester.pumpAndSettle();

    expect(resolvedBrightness(tester), Brightness.dark);
  });
}

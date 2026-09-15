import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/services/storage_service.dart';
import 'package:freedium/core/services/theme_service.dart';
import 'package:freedium/features/settings/controllers/settings_controller.dart';
import 'package:freedium/features/settings/views/settings_page.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart' as ui;
import 'package:material_ui/material_ui.dart';

class MockStorageService extends StorageService {
  bool _isDarkMode = false;

  @override
  bool get isDarkMode => _isDarkMode;

  @override
  set isDarkMode(bool value) {
    _isDarkMode = value;
  }

  @override
  double get fontSize => 16.0;

  @override
  List<dynamic> get favorites => [];
}

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
    Get.put(SettingsController());
  });

  Widget buildTestApp() {
    return M3ETheme(
      data: M3EThemeData.light(seedColor: const Color(0xFF006A6A)),
      child: const GetMaterialApp(
        localizationsDelegates: [ui.DefaultMaterialLocalizations.delegate],
        home: SettingsPage(),
      ),
    );
  }

  testWidgets('SettingsPage renders without layout errors', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('Send Feedback'), findsOneWidget);

    final errors = tester.takeException();
    expect(errors, isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/app.dart';
import 'package:freedium/core/services/clipboard_service.dart';
import 'package:freedium/core/services/theme_service.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_env.dart';

/// Verifies the app's M3E theme actually follows [ThemeService], end to end.
///
/// The service-level tests cover the stored preference; this one covers the
/// wiring in [Freedium] — that flipping the theme rebuilds the tree to the new
/// brightness instead of leaving it pinned to whatever it started with.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    registerServices();
    Get.put<ClipboardService>(ClipboardService());
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

  testWidgets('a stored dark preference is applied on startup', (tester) async {
    Get.find<ThemeService>().toggleTheme(true);

    await tester.pumpWidget(const Freedium());
    await tester.pumpAndSettle();

    expect(resolvedBrightness(tester), Brightness.dark);
  });
}

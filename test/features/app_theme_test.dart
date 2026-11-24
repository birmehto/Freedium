import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/app.dart';
import 'package:freedium/core/controllers/app_controllers.dart';
import 'package:freedium/core/storage/preferences_store.dart';
import 'package:freedium/core/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_env.dart';

/// Verifies the app's theme actually follows [ThemeController], end to end.
///
/// The controller-level tests cover the stored preference and its state; this
/// one covers the wiring in [Freedium] — that flipping the theme rebuilds the
/// tree to the new brightness instead of leaving it pinned to whatever it
/// started with.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Brightness resolvedBrightness(WidgetTester tester) {
    final context = tester.element(find.byType(Scaffold).first);
    return Theme.of(context).brightness;
  }

  testWidgets('theme controller toggle switches the resolved theme', (
    tester,
  ) async {
    final services = registerServices();
    final theme = services.container.read(themeControllerProvider.notifier);

    await tester.pumpWidget(wrapTestApp(child: const Freedium()));
    await tester.pumpAndSettle();

    expect(resolvedBrightness(tester), Brightness.dark);

    theme.toggleTheme(false);
    await tester.pumpAndSettle();

    expect(resolvedBrightness(tester), Brightness.light);
    expect(
      services.container.read(themeControllerProvider).preferredMode,
      PreferencesStore.modeLight,
    );

    theme.toggleTheme(true);
    await tester.pumpAndSettle();

    expect(resolvedBrightness(tester), Brightness.dark);
  });

  testWidgets('a stored dark preference is applied on startup', (tester) async {
    final services = registerServices(
      seed: {PreferencesStore.themeModeKey: PreferencesStore.modeDark},
    );

    await tester.pumpWidget(wrapTestApp(child: const Freedium()));
    await tester.pumpAndSettle();

    expect(resolvedBrightness(tester), Brightness.dark);
    expect(
      AppTheme.themeMode(
        services.container.read(themeControllerProvider).preferredMode,
      ),
      ThemeMode.dark,
    );
  });
}

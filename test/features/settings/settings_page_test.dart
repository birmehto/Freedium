import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/features/settings/controllers/settings_controller.dart';
import 'package:freedium/features/settings/models/reader_settings.dart';
import 'package:freedium/features/settings/views/settings_page.dart';
import 'package:get/get.dart';

import '../../helpers/test_env.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final services = registerServices();
    Get.put(SettingsController(services.theme, services.storage));
  });

  testWidgets('renders without layout errors', (tester) async {
    await tester.pumpWidget(wrapTestApp(child: const SettingsPage()));
    await tester.pumpAndSettle();

    expect(find.text('Dark Mode'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reaches the about section', (tester) async {
    await tester.pumpWidget(wrapTestApp(child: const SettingsPage()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Send Feedback'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Send Feedback'), findsOneWidget);
  });

  testWidgets('shows the stored font size in the reader appearance sheet', (
    tester,
  ) async {
    final services = registerServices();
    services.storage.preferences.readerSettings = const ReaderSettings(
      fontSize: 21,
    );
    Get.put(SettingsController(services.theme, services.storage));

    await tester.pumpWidget(wrapTestApp(child: const SettingsPage()));
    await tester.pumpAndSettle();

    // The size is configured in the sheet, not on the page itself.
    expect(find.text('21 px'), findsNothing);

    await tester.tap(find.text('Reader Appearance'));
    await tester.pumpAndSettle();

    expect(find.text('21 px'), findsOneWidget);
  });

  testWidgets('previews the active reader palette in the appearance sheet', (
    tester,
  ) async {
    await tester.pumpWidget(wrapTestApp(child: const SettingsPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reader Appearance'));
    await tester.pumpAndSettle();

    // The preview paints a miniature of the reader from the current settings.
    expect(find.text('The shape of readable text'), findsOneWidget);
    expect(find.text('Read the full story'), findsOneWidget);
  });

  testWidgets('reset is disabled while the appearance is already default', (
    tester,
  ) async {
    await tester.pumpWidget(wrapTestApp(child: const SettingsPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reader Appearance'));
    await tester.pumpAndSettle();

    final reset = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('Reset defaults'),
        matching: find.bySubtype<TextButton>(),
      ),
    );
    expect(reset.onPressed, isNull);
  });

  testWidgets('reset returns the appearance to defaults', (tester) async {
    final services = registerServices();
    services.storage.preferences.readerSettings = const ReaderSettings(
      fontSize: 21,
    );
    Get.put(SettingsController(services.theme, services.storage));

    await tester.pumpWidget(wrapTestApp(child: const SettingsPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reader Appearance'));
    await tester.pumpAndSettle();

    expect(find.text('21 px'), findsOneWidget);

    // The reset action sits below the fold in the test viewport.
    await tester.ensureVisible(find.text('Reset defaults'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reset defaults'));
    await tester.pumpAndSettle();

    expect(find.text('21 px'), findsNothing);
    expect(find.text('17 px'), findsOneWidget);
  });

  testWidgets('offers no separate font size entry', (tester) async {
    // Reader typography is edited in one place, so there is no second tile
    // that opens a sheet of its own.
    await tester.pumpWidget(wrapTestApp(child: const SettingsPage()));
    await tester.pumpAndSettle();

    expect(find.text('Default Font Size'), findsNothing);
    expect(find.text('Reader'), findsNothing);
  });

  testWidgets('offers no storage section', (tester) async {
    // Saved articles are managed from the reader's own save button, so the
    // settings screen has no cache section to open or clear.
    await tester.pumpWidget(wrapTestApp(child: const SettingsPage()));
    await tester.pumpAndSettle();

    expect(find.text('Storage'), findsNothing);
    expect(find.text('Offline Articles'), findsNothing);
  });
}

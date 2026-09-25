import 'package:flutter/material.dart' show Scrollable;
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

  testWidgets('shows the stored default font size', (tester) async {
    final services = registerServices();
    services.storage.preferences.readerSettings = const ReaderSettings(
      fontSize: 21,
    );
    Get.put(SettingsController(services.theme, services.storage));

    await tester.pumpWidget(wrapTestApp(child: const SettingsPage()));
    await tester.pumpAndSettle();

    expect(find.text('21 px'), findsOneWidget);
  });
}

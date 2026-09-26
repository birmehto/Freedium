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

  testWidgets('shows how much is saved for offline reading', (tester) async {
    // A fresh set of services, so the cache is written before the controller
    // starts counting it.
    final services = registerServices();
    await services.storage.cache.save(
      url: 'https://medium.com/a',
      html: '<article><p>A story kept on the device.</p></article>',
      title: 'A Story',
    );
    Get.put(SettingsController(services.theme, services.storage));

    await tester.pumpWidget(wrapTestApp(child: const SettingsPage()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Offline Articles'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('1 article'), findsOneWidget);
  });

  testWidgets('clears the offline cache from the storage section', (
    tester,
  ) async {
    final services = registerServices();
    await services.storage.cache.save(
      url: 'https://medium.com/a',
      html: '<article><p>A story kept on the device.</p></article>',
    );
    final controller = SettingsController(services.theme, services.storage);
    Get.put(controller);

    await tester.pumpWidget(wrapTestApp(child: const SettingsPage()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Offline Articles'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Offline Articles'));
    await tester.pumpAndSettle();

    expect(find.text('Clear saved articles'), findsOneWidget);
    expect(services.storage.cache.cachedCount.value, 1);

    await tester.tap(find.text('Clear saved articles'));
    await tester.pumpAndSettle();

    expect(services.storage.cache.cachedCount.value, 0);
    expect(
      await services.storage.cache.contains('https://medium.com/a'),
      isFalse,
    );
    expect(controller.hasOfflineArticles, isFalse);
  });

  testWidgets('offers nothing to clear when nothing is saved', (tester) async {
    await tester.pumpWidget(wrapTestApp(child: const SettingsPage()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Offline Articles'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Offline Articles'));
    await tester.pumpAndSettle();

    expect(find.text('Nothing is saved yet.'), findsOneWidget);
    expect(find.text('Clear saved articles'), findsNothing);
  });
}

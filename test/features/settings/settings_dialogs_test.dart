import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/config/mirror_source.dart';
import 'package:freedium/core/providers/service_providers.dart';
import 'package:freedium/core/storage/preferences_store.dart';
import 'package:freedium/features/settings/widgets/settings_dialogs.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/test_env.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestServices services;

  setUp(() {
    services = registerServices();
  });

  Widget buildHost(void Function(BuildContext) open) => wrapTestApp(
    services: services,
    child: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => open(context),
          child: const Text('open'),
        ),
      ),
    ),
  );

  Future<void> openDialog(
    WidgetTester tester,
    void Function(BuildContext) show,
  ) async {
    await tester.pumpWidget(buildHost(show));
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('showMirrorDialog', () {
    testWidgets('lists every configured mirror and Auto', (tester) async {
      await openDialog(tester, showMirrorDialog);

      expect(find.text('Auto'), findsOneWidget);
      for (final mirror in MirrorCatalog.createDefaults()) {
        expect(find.text(mirror.name), findsOneWidget);
      }
    });

    testWidgets('persists the chosen mirror id', (tester) async {
      await openDialog(tester, showMirrorDialog);

      await tester.tap(find.text('Freedium Web'));
      await tester.pumpAndSettle();

      expect(services.storage.preferences.preferredMirror, 'mirror');
      expect(
        services.container
            .read(articleResolverProvider)
            .sources
            .firstWhere((source) => source.id == 'mirror')
            .name,
        'Freedium Web',
      );
    });

    testWidgets('Auto clears the stored preference', (tester) async {
      services.storage.preferences.preferredMirror = 'mirror';

      await openDialog(tester, showMirrorDialog);

      await tester.tap(find.text('Auto'));
      await tester.pumpAndSettle();

      expect(services.storage.preferences.preferredMirror, isNull);
    });
  });

  group('showThemeDialog', () {
    testWidgets('persists an explicit theme mode', (tester) async {
      await openDialog(tester, showThemeDialog);

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(services.storage.preferences.themeMode, PreferencesStore.modeDark);
    });
  });

  group('showCreditsDialog', () {
    testWidgets('keeps the legal bit short and friendly', (tester) async {
      await openDialog(tester, showCreditsDialog);

      expect(find.text('Licenses & Credits'), findsOneWidget);
      expect(find.textContaining('Not affiliated with'), findsOneWidget);
      expect(
        find.textContaining('Stories belong to their authors'),
        findsOneWidget,
      );
      expect(find.textContaining('MIT licensed'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
      expect(find.text('Open-source licenses'), findsNothing);
    });
  });
}

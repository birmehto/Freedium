import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/providers/service_providers.dart';
import 'package:freedium/core/services/clipboard_service.dart';
import 'package:freedium/core/services/share_intent_service.dart';
import 'package:freedium/features/home/controllers/home_controller.dart';
import 'package:freedium/features/home/views/home_page.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/test_env.dart';

class _FakeClipboard extends ClipboardService {
  _FakeClipboard(this.text);

  final String? text;
  int calls = 0;

  @override
  Future<String?> getFromClipboard() async {
    calls++;
    return text;
  }
}

({ProviderContainer container, _FakeClipboard clipboard})
containerWithClipboard(String? text) {
  final storage = createTestStorage();
  final clipboard = _FakeClipboard(text);
  final container = ProviderContainer(
    overrides: [
      storageServiceProvider.overrideWithValue(storage),
      shareIntentServiceProvider.overrideWithValue(
        ShareIntentService(storage.preferences),
      ),
      clipboardServiceProvider.overrideWithValue(clipboard),
    ],
  );
  addTearDown(container.dispose);
  return (container: container, clipboard: clipboard);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomePage', () {
    testWidgets('renders the masthead and the unlock form', (tester) async {
      registerServices();

      await tester.pumpWidget(wrapTestApp(child: const HomePage()));
      await tester.pumpAndSettle();

      expect(find.text('Freedium'), findsOneWidget);
      expect(find.text('ARTICLE URL'), findsOneWidget);
      expect(find.text('Unlock story'), findsOneWidget);
      expect(find.text('Copy a link'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('rejects input that is not a URL', (tester) async {
      registerServices();

      await tester.pumpWidget(wrapTestApp(child: const HomePage()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'not a url');
      await tester.tap(find.text('Unlock story'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid URL'), findsOneWidget);
    });

    testWidgets('rejects a valid URL that is not Medium', (tester) async {
      registerServices();

      await tester.pumpWidget(wrapTestApp(child: const HomePage()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'https://google.com');
      await tester.tap(find.text('Unlock story'));
      await tester.pumpAndSettle();

      expect(find.text('Only Medium links are supported'), findsOneWidget);
    });

    testWidgets('stays quiet until the form is submitted', (tester) async {
      registerServices();

      await tester.pumpWidget(wrapTestApp(child: const HomePage()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'not a url');
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid URL'), findsNothing);
    });

    testWidgets('clears the validation message once the URL is corrected', (
      tester,
    ) async {
      registerServices();

      await tester.pumpWidget(wrapTestApp(child: const HomePage()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'not a url');
      await tester.tap(find.text('Unlock story'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid URL'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField),
        'https://medium.com/@user/a-story',
      );
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid URL'), findsNothing);
    });

    testWidgets('updates the message while the URL stays invalid', (
      tester,
    ) async {
      registerServices();

      await tester.pumpWidget(wrapTestApp(child: const HomePage()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'not a url');
      await tester.tap(find.text('Unlock story'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid URL'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'https://google.com');
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid URL'), findsNothing);
      expect(find.text('Only Medium links are supported'), findsOneWidget);
    });

    testWidgets('clears the validation message when the field is cleared', (
      tester,
    ) async {
      registerServices();

      await tester.pumpWidget(wrapTestApp(child: const HomePage()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'not a url');
      await tester.tap(find.text('Unlock story'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid URL'), findsOneWidget);

      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid URL'), findsNothing);
    });

    testWidgets('enables the article for a Medium URL', (tester) async {
      final services = registerServices();

      await tester.pumpWidget(
        wrapTestApp(services: services, child: const HomePage()),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField),
        'https://medium.com/@user/a-story',
      );
      await tester.pump();

      expect(
        services.container.read(homeControllerProvider.notifier).canOpenArticle,
        isTrue,
      );
    });

    testWidgets('pastes a trimmed URL from the clipboard', (tester) async {
      final fixtures = containerWithClipboard(
        '  https://medium.com/@user/pasted  ',
      );

      await tester.pumpWidget(
        wrapTestApp(container: fixtures.container, child: const HomePage()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.clipboardPaste));
      await tester.pumpAndSettle();

      expect(fixtures.clipboard.calls, 1);
      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(field.controller?.text, 'https://medium.com/@user/pasted');
      expect(find.byIcon(LucideIcons.x), findsOneWidget);
    });

    testWidgets('clears the field with the trailing action', (tester) async {
      registerServices();

      await tester.pumpWidget(wrapTestApp(child: const HomePage()));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField),
        'https://medium.com/@user/a-story',
      );
      await tester.pump();

      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pumpAndSettle();

      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(field.controller?.text, isEmpty);
      expect(find.byIcon(LucideIcons.clipboardPaste), findsOneWidget);
    });

    testWidgets('reports an empty clipboard without changing the field', (
      tester,
    ) async {
      final fixtures = containerWithClipboard(null);

      await tester.pumpWidget(
        wrapTestApp(container: fixtures.container, child: const HomePage()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.clipboardPaste));
      await tester.pumpAndSettle();

      expect(fixtures.clipboard.calls, 1);
      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(field.controller?.text, isEmpty);
    });
  });
}

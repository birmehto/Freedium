import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/features/support/controllers/support_controller.dart';
import 'package:freedium/features/support/widgets/support_dialog.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/test_env.dart';

/// Records the choice instead of performing it, so the dialog can be tested
/// without a browser.
class _SpySupportController extends SupportController {
  int coffeeCalls = 0;

  @override
  Future<void> buyCoffee() async => coffeeCalls++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _SpySupportController spy;

  setUp(() {
    registerServices();
    spy = _SpySupportController();
  });

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      wrapTestApp(
        overrides: [supportControllerProvider.overrideWithValue(spy)],
        child: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showSupportDialog(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('showSupportDialog', () {
    testWidgets('offers the donation', (tester) async {
      await openDialog(tester);

      expect(find.text('Buy me a coffee'), findsOneWidget);
      expect(find.text('Maybe later'), findsOneWidget);
    });

    testWidgets('the coffee option closes the dialog and opens the page', (
      tester,
    ) async {
      await openDialog(tester);

      await tester.tap(find.text('Buy me a coffee'));
      await tester.pumpAndSettle();

      expect(spy.coffeeCalls, 1);
      expect(find.text('Buy me a coffee'), findsNothing);
    });

    testWidgets('Maybe later dismisses without choosing', (tester) async {
      await openDialog(tester);

      await tester.tap(find.text('Maybe later'));
      await tester.pumpAndSettle();

      expect(spy.coffeeCalls, 0);
      expect(find.text('Buy me a coffee'), findsNothing);
    });
  });
}

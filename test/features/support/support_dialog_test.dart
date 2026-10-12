import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/features/support/controllers/support_controller.dart';
import 'package:freedium/features/support/widgets/support_dialog.dart';

import '../../helpers/test_env.dart';

/// Records the choice instead of performing it, so the dialog can be tested
/// without an ad player or a browser.
class _SpySupportController extends SupportController {
  _SpySupportController(super.ads);

  int watchAdCalls = 0;
  int coffeeCalls = 0;

  @override
  Future<void> watchAd() async => watchAdCalls++;

  @override
  Future<void> buyCoffee() async => coffeeCalls++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _SpySupportController controller;

  setUp(() {
    controller = _SpySupportController(registerServices().ads);
  });

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      wrapTestApp(
        child: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showSupportDialog(context, controller: controller),
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
    testWidgets('offers both ways to support', (tester) async {
      await openDialog(tester);

      expect(find.text('Watch a short ad'), findsOneWidget);
      expect(find.text('Buy me a coffee'), findsOneWidget);
      expect(find.text('Maybe later'), findsOneWidget);
    });

    testWidgets('the ad option closes the dialog and starts the ad', (
      tester,
    ) async {
      await openDialog(tester);

      await tester.tap(find.text('Watch a short ad'));
      await tester.pumpAndSettle();

      expect(controller.watchAdCalls, 1);
      expect(find.text('Watch a short ad'), findsNothing);
    });

    testWidgets('the coffee option closes the dialog and opens the page', (
      tester,
    ) async {
      await openDialog(tester);

      await tester.tap(find.text('Buy me a coffee'));
      await tester.pumpAndSettle();

      expect(controller.coffeeCalls, 1);
      expect(find.text('Buy me a coffee'), findsNothing);
    });

    testWidgets('Maybe later dismisses without choosing', (tester) async {
      await openDialog(tester);

      await tester.tap(find.text('Maybe later'));
      await tester.pumpAndSettle();

      expect(controller.watchAdCalls, 0);
      expect(controller.coffeeCalls, 0);
      expect(find.text('Watch a short ad'), findsNothing);
    });
  });
}

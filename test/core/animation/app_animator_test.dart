import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/animation/app_animator.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget host(Widget child) => Directionality(
    textDirection: TextDirection.ltr,
    child: SizedBox(width: 300, height: 300, child: child),
  );

  group('AppAnimator', () {
    testWidgets('entrance fades its child in', (tester) async {
      await tester.pumpWidget(
        host(
          AppAnimator.entrance(
            delay: const Duration(milliseconds: 20),
            child: const Text('Hello'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('switcher replaces the old child when the key changes', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(AppAnimator.switcher(key: 0, child: const Text('First'))),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        host(AppAnimator.switcher(key: 1, child: const Text('Second'))),
      );
      await tester.pumpAndSettle();

      expect(find.text('First'), findsNothing);
      expect(find.text('Second'), findsOneWidget);
    });

    testWidgets('pulse keeps the same child when its value changes', (
      tester,
    ) async {
      Widget build(Object value) => host(
        AppAnimator.pulse(value: value, child: const Icon(Icons.star)),
      );

      await tester.pumpWidget(build(true));
      await tester.pumpAndSettle();

      await tester.pumpWidget(build(false));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('page route exposes the pushed page', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      );

      navigatorKey.currentState!.push(
        AppAnimator.pageRoute<void>(const Scaffold(body: Text('Pushed'))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pushed'), findsOneWidget);
    });
  });
}

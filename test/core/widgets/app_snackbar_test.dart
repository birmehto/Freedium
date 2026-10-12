import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:freedium/core/widgets/app_snackbar.dart';

void main() {
  group('AppSnackbar.show', () {
    testWidgets('shows the message on the nearest ScaffoldMessenger',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
      );

      final context = tester.element(find.byType(Scaffold));
      AppSnackbar.show(context, message: 'Saved');

      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.behavior, SnackBarBehavior.floating);
    });

    testWidgets('is silent when the context was unmounted', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SizedBox(key: key))),
      );
      final deadContext = key.currentContext!;
      expect(deadContext.mounted, isTrue);

      // Remount without the keyed subtree: the captured context is now
      // deactivated, the same living-context-behind-a-swipe the dialog fix
      // had to survive.
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
      );
      expect(deadContext.mounted, isFalse);

      expect(
        () => AppSnackbar.show(deadContext, message: 'ghost message'),
        returnsNormally,
      );
      await tester.pump();
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('is silent when there is no ScaffoldMessenger ancestor',
        (tester) async {
      BuildContext? context;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (builderContext) {
              context = builderContext;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(
        () => AppSnackbar.show(context, message: 'no shell'),
        returnsNormally,
      );
      await tester.pump();
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('is silent on a null context', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
      );

      expect(() => AppSnackbar.show(null, message: 'no context'), returnsNormally);
      await tester.pump();
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('shows one at a time: the latest replaces the previous',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
      );

      final context = tester.element(find.byType(Scaffold));
      AppSnackbar.show(context, message: 'first');
      await tester.pump();

      AppSnackbar.show(context, message: 'second');
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('second'), findsOneWidget);
      expect(find.text('first'), findsNothing);
    });
  });
}
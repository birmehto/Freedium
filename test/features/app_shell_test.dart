import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/app_shell.dart';

import '../helpers/test_env.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppShell', () {
    testWidgets('starts on Home', (tester) async {
      registerServices();

      await tester.pumpWidget(wrapTestApp(child: const AppShell()));
      await tester.pumpAndSettle();

      expect(find.text('ARTICLE URL'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('switches to the library and back to settings', (tester) async {
      registerServices();

      await tester.pumpWidget(wrapTestApp(child: const AppShell()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();
      expect(find.text('Your library'), findsOneWidget);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsWidgets);
      expect(find.text('Dark Mode'), findsOneWidget);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('ARTICLE URL'), findsOneWidget);
    });
  });
}

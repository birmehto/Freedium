import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/services/ad_service.dart';
import 'package:freedium/features/support/controllers/support_controller.dart';
import 'package:freedium/features/support/widgets/support_dialog.dart';

import '../../helpers/test_env.dart';

/// Records the choice instead of performing it, so the dialog can be tested
/// without an ad player or a browser, and reports the outcome the test sets.
class _SpySupportController extends SupportController {
  _SpySupportController(super.ads);

  RewardedAdOutcome outcome = RewardedAdOutcome.earnedReward;

  @override
  AdFailureReason adFailureReason = AdFailureReason.unknown;

  int watchAdCalls = 0;
  int coffeeCalls = 0;

  @override
  Future<RewardedAdOutcome> watchAd() async {
    watchAdCalls++;
    return outcome;
  }

  @override
  Future<void> buyCoffee() async => coffeeCalls++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _SpySupportController controller;

  setUp(() {
    controller = _SpySupportController(registerServices().ads);
  });

  Future<void> openDialog(WidgetTester tester, {bool settle = true}) async {
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
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      // A running CircularProgressIndicator never settles, so an un-settled
      // open advances the route animation by hand instead.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  Future<void> tapAd(WidgetTester tester) async {
    await tester.tap(find.text('Watch a short ad'));
    await tester.pumpAndSettle();
  }

  group('showSupportDialog', () {
    testWidgets('offers both ways to support', (tester) async {
      await openDialog(tester);

      expect(find.text('Watch a short ad'), findsOneWidget);
      expect(find.text('Buy me a coffee'), findsOneWidget);
      expect(find.text('Maybe later'), findsOneWidget);
    });

    testWidgets('does not start an ad just because it opens', (tester) async {
      final ads = registerServices().ads as FakeAdService;
      controller = _SpySupportController(ads);

      await openDialog(tester);

      // Ads are warmed at app startup, so opening the sheet must not kick off
      // a fresh request the user then has to wait on.
      expect(ads.prepareCount, 0);
    });

    testWidgets('shows progress while the ad is loading', (tester) async {
      final ads = registerServices().ads as FakeAdService;
      ads.isLoading.value = true;
      controller = _SpySupportController(ads);

      await openDialog(tester, settle: false);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.textContaining('Preparing'), findsOneWidget);
    });

    testWidgets('the ad option closes the dialog and starts the ad', (
      tester,
    ) async {
      await openDialog(tester);

      await tapAd(tester);

      expect(controller.watchAdCalls, 1);
      expect(find.text('Watch a short ad'), findsNothing);
    });

    testWidgets('thanks the user when the reward is earned', (tester) async {
      controller.outcome = RewardedAdOutcome.earnedReward;

      await openDialog(tester);
      await tapAd(tester);

      expect(find.textContaining('Thank you'), findsOneWidget);
    });

    testWidgets('explains a blocked ad only after the user picks it', (
      tester,
    ) async {
      controller.outcome = RewardedAdOutcome.unavailable;
      controller.adFailureReason = AdFailureReason.noConnection;

      await openDialog(tester);

      // Nothing about blocking is shown before the choice is made.
      expect(find.textContaining('AdGuard'), findsNothing);

      await tapAd(tester);

      expect(find.text('Ads are blocked'), findsOneWidget);
      expect(find.textContaining('AdGuard'), findsOneWidget);
      expect(find.text('Buy me a coffee'), findsOneWidget);
    });

    testWidgets('says there is no ad when the server had no fill', (
      tester,
    ) async {
      controller.outcome = RewardedAdOutcome.unavailable;
      controller.adFailureReason = AdFailureReason.noFill;

      await openDialog(tester);
      await tapAd(tester);

      expect(find.text('No ad available'), findsOneWidget);
      expect(find.textContaining('AdGuard'), findsNothing);
    });

    testWidgets('says the ad is misconfigured for an invalid request', (
      tester,
    ) async {
      controller.outcome = RewardedAdOutcome.unavailable;
      controller.adFailureReason = AdFailureReason.invalidRequest;

      await openDialog(tester);
      await tapAd(tester);

      expect(find.text('Ads are not set up'), findsOneWidget);
    });

    testWidgets('says the ad timed out when it took too long', (tester) async {
      controller.outcome = RewardedAdOutcome.unavailable;
      controller.adFailureReason = AdFailureReason.timeout;

      await openDialog(tester);
      await tapAd(tester);

      expect(find.text('The ad took too long'), findsOneWidget);
    });

    testWidgets('says the server failed for a server-side error', (
      tester,
    ) async {
      controller.outcome = RewardedAdOutcome.unavailable;
      controller.adFailureReason = AdFailureReason.serverError;

      await openDialog(tester);
      await tapAd(tester);

      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('the sad dialog can send the user to the donation page', (
      tester,
    ) async {
      controller.outcome = RewardedAdOutcome.unavailable;
      controller.adFailureReason = AdFailureReason.noConnection;

      await openDialog(tester);
      await tapAd(tester);
      await tester.tap(find.text('Buy me a coffee'));
      await tester.pumpAndSettle();

      expect(controller.coffeeCalls, 1);
      expect(find.text('Ads are blocked'), findsNothing);
    });

    testWidgets('stays quiet when the user closes the ad early', (
      tester,
    ) async {
      controller.outcome = RewardedAdOutcome.dismissed;

      await openDialog(tester);
      await tapAd(tester);

      expect(find.byType(SnackBar), findsNothing);
      expect(find.text('No ad available'), findsNothing);
      expect(find.text('Ads are blocked'), findsNothing);
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

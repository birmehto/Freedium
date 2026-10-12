import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/services/ad_service.dart';
import 'package:freedium/features/support/controllers/support_controller.dart';

import '../../helpers/test_env.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAdService ads;
  late SupportController controller;

  setUp(() {
    ads = registerServices().ads as FakeAdService;
    controller = SupportController(ads);
  });

  group('SupportController', () {
    test('adReady mirrors the ad service', () {
      ads.isReady.value = false;
      expect(controller.adReady, isFalse);

      ads.isReady.value = true;
      expect(controller.adReady, isTrue);
    });

    test('watchAd presents a video and consumes the attempt', () async {
      await controller.watchAd();

      expect(ads.showCount, 1);
    });

    test('watchAd reports each outcome without throwing', () async {
      for (final outcome in RewardedAdOutcome.values) {
        ads.outcome = outcome;

        await expectLater(controller.watchAd(), completes);
      }

      expect(ads.showCount, RewardedAdOutcome.values.length);
    });

    testWidgets('thanks the user after a rewarded video', (tester) async {
      ads.outcome = RewardedAdOutcome.earnedReward;

      await tester.pumpWidget(
        wrapTestApp(child: const Scaffold(body: SizedBox.shrink())),
      );

      await controller.watchAd();
      await tester.pumpAndSettle();

      expect(find.textContaining('Thank you'), findsOneWidget);
    });

    testWidgets('explains when no ad could be shown', (tester) async {
      ads.outcome = RewardedAdOutcome.unavailable;

      await tester.pumpWidget(
        wrapTestApp(child: const Scaffold(body: SizedBox.shrink())),
      );

      await controller.watchAd();
      await tester.pumpAndSettle();

      expect(find.textContaining('No ad is ready'), findsOneWidget);
    });

    testWidgets('stays quiet when the user closes the ad early', (
      tester,
    ) async {
      ads.outcome = RewardedAdOutcome.dismissed;

      await tester.pumpWidget(
        wrapTestApp(child: const Scaffold(body: SizedBox.shrink())),
      );

      await controller.watchAd();
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });
  });
}

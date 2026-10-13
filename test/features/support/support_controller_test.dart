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

    test('adLoading mirrors the ad service', () {
      ads.isLoading.value = false;
      expect(controller.adLoading, isFalse);

      ads.isLoading.value = true;
      expect(controller.adLoading, isTrue);
    });

    test('adFailureReason mirrors the ad service', () {
      ads.lastFailureReason = AdFailureReason.noFill;

      expect(controller.adFailureReason, AdFailureReason.noFill);
    });

    test('watchAd presents a video and consumes the attempt', () async {
      await controller.watchAd();

      expect(ads.showCount, 1);
    });

    test('watchAd reports each outcome the ad service returns', () async {
      for (final outcome in RewardedAdOutcome.values) {
        ads.outcome = outcome;

        expect(await controller.watchAd(), outcome);
      }

      expect(ads.showCount, RewardedAdOutcome.values.length);
    });
  });
}

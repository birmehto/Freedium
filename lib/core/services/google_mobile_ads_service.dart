import 'dart:io';

import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constants/ad_config.dart';
import '../utils/app_log.dart';
import 'ad_service.dart';

/// [AdService] backed by Google Mobile Ads.
///
/// Only Android and iOS ship the SDK. On any other platform the service stays
/// idle and reports [RewardedAdOutcome.unavailable], so callers never need a
/// platform check of their own.
class GoogleMobileAdsService implements AdService {
  @override
  final RxBool isReady = false.obs;

  RewardedAd? _rewardedAd;
  bool _initialized = false;

  bool get _isSupported => Platform.isAndroid || Platform.isIOS;

  @override
  Future<void> initialize() async {
    if (_initialized || !_isSupported) return;
    _initialized = true;

    try {
      await MobileAds.instance.initialize();
      _load();
    } catch (error) {
      appLog('Ad init failed: $error', name: 'Ads', level: LogLevel.warning);
    }
  }

  @override
  Future<RewardedAdOutcome> showRewarded() async {
    final ad = _rewardedAd;

    if (ad == null) {
      // Nothing is loaded: start a load so the next attempt can succeed, and
      // report that this one could not present anything.
      _load();
      return RewardedAdOutcome.unavailable;
    }

    _rewardedAd = null;
    isReady.value = false;

    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _load();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        appLog(
          'Ad failed to show: ${error.message}',
          name: 'Ads',
          level: LogLevel.warning,
        );
        ad.dispose();
        _load();
      },
    );

    try {
      await ad.show(onUserEarnedReward: (_, _) => earned = true);
    } catch (error) {
      appLog('Ad show threw: $error', name: 'Ads', level: LogLevel.warning);
      return RewardedAdOutcome.unavailable;
    }

    return earned
        ? RewardedAdOutcome.earnedReward
        : RewardedAdOutcome.dismissed;
  }

  /// Requests one rewarded ad, keeping the previous one until a replacement
  /// arrives so a fine-grained reload never leaves the button empty.
  void _load() {
    if (!_isSupported) return;

    RewardedAd.load(
      adUnitId: AdConfig.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          isReady.value = true;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          isReady.value = false;
          appLog(
            'Ad failed to load: ${error.message}',
            name: 'Ads',
            level: LogLevel.warning,
          );
        },
      ),
    );
  }
}

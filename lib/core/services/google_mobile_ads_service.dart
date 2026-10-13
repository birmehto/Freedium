import 'dart:io';

import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/env.dart';
import '../utils/app_log.dart';
import 'ad_failure.dart';
import 'ad_service.dart';

/// [AdService] backed by Google Mobile Ads.
///
/// Only Android and iOS ship the SDK. On any other platform the service stays
/// idle, reports [AdFailureReason.unsupported], and answers
/// [RewardedAdOutcome.unavailable], so callers never need a platform check of
/// their own.
///
/// The SDK is initialized on the first [prepare], which the app calls once at
/// startup so the support flow never has to wait for a video.
class GoogleMobileAdsService implements AdService {
  @override
  final RxBool isReady = false.obs;

  @override
  final RxBool isLoading = false.obs;

  @override
  AdFailureReason get lastFailureReason => _lastFailure;
  AdFailureReason _lastFailure = AdFailureReason.unknown;

  RewardedAd? _rewardedAd;
  Future<void>? _initFuture;
  bool _loading = false;

  bool get _isSupported => Platform.isAndroid || Platform.isIOS;

  @override
  Future<void> prepare() async {
    if (!_isSupported) {
      _lastFailure = AdFailureReason.unsupported;
      return;
    }
    if (_rewardedAd != null) return;

    // The SDK handshake can take a moment too, so the progress state starts
    // before the first await rather than only when the request goes out.
    isLoading.value = true;

    _initFuture ??= _initialize();
    await _initFuture;

    if (_rewardedAd == null) {
      _load();
    } else {
      isLoading.value = false;
    }
  }

  @override
  Future<RewardedAdOutcome> showRewarded() async {
    if (!_isSupported) {
      _lastFailure = AdFailureReason.unsupported;
      return RewardedAdOutcome.unavailable;
    }

    final ad = _rewardedAd;

    if (ad == null) {
      // Nothing is loaded: start a load so the next attempt can succeed, and
      // report that this one could not present anything. The caller reads
      // [lastFailureReason] to explain why.
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
        _lastFailure = _classify(error);
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

  Future<void> _initialize() async {
    try {
      await MobileAds.instance.initialize();
    } catch (error) {
      appLog('Ad init failed: $error', name: 'Ads', level: LogLevel.warning);
    }
  }

  /// Requests one rewarded ad for the next attempt.
  void _load() {
    if (!_isSupported || _loading) return;

    _loading = true;
    isLoading.value = true;
    RewardedAd.load(
      adUnitId: AdEnv.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          isLoading.value = false;
          _rewardedAd = ad;
          isReady.value = true;
        },
        onAdFailedToLoad: (error) {
          _loading = false;
          isLoading.value = false;
          _rewardedAd = null;
          isReady.value = false;
          _lastFailure = _classify(error);
          appLog(
            'Ad failed to load (code ${error.code}): ${error.message}',
            name: 'Ads',
            level: LogLevel.warning,
          );
        },
      ),
    );
  }

  AdFailureReason _classify(AdError error) => classifyAdFailure(
    code: error.code,
    message: error.message,
    isAndroid: Platform.isAndroid,
  );
}

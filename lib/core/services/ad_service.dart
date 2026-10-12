import 'package:get/get.dart';

/// How a rewarded-video attempt ended.
enum RewardedAdOutcome {
  /// The user watched far enough to earn the reward.
  earnedReward,

  /// The user dismissed the ad before the reward was earned.
  dismissed,

  /// No ad could be presented — not loaded yet, or no SDK on this platform.
  unavailable,
}

/// Presents full-screen rewarded video ads.
///
/// An interface rather than a direct SDK call, so the support flow can be
/// tested without a device and the app does not care whether a real ad network
/// is wired up (desktop builds have none).
abstract interface class AdService {
  /// True while a rewarded ad is loaded and ready to present.
  RxBool get isReady;

  /// Prepares the SDK and loads the first ad.
  ///
  /// Safe to call once, and safe on platforms without an ad SDK — where it
  /// simply stays idle.
  Future<void> initialize();

  /// Presents a rewarded video, completing with how the attempt ended.
  Future<RewardedAdOutcome> showRewarded();
}

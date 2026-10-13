import 'package:get/get.dart';

/// How a rewarded-video attempt ended.
enum RewardedAdOutcome {
  /// The user watched far enough to earn the reward.
  earnedReward,

  /// The user dismissed the ad before the reward was earned.
  dismissed,

  /// No ad could be presented. [AdService.lastFailureReason] says why.
  unavailable,
}

/// Why an ad request produced no ad to show.
///
/// AdMob reports many different conditions behind the single "the ad did not
/// load", and each deserves its own explanation — a blocked or offline device
/// needs a different answer from one where the server simply had no inventory,
/// and neither is the same as a misconfigured app. [AdService] classifies the
/// SDK error into one of these so the UI can say the right thing every time.
enum AdFailureReason {
  /// The ad server could not be reached: no connection, or an ad blocker /
  /// private DNS (for example AdGuard) dropping requests to Google's domains.
  noConnection,

  /// The server answered but had no ad to fill the request.
  noFill,

  /// The request was rejected as malformed — typically a wrong ad unit ID or a
  /// missing AdMob app ID.
  invalidRequest,

  /// No ad arrived before the request timed out.
  timeout,

  /// The ad server failed to process the request.
  serverError,

  /// This platform has no ad SDK at all (desktop builds).
  unsupported,

  /// The failure did not match any condition we know how to explain.
  unknown,
}

/// Presents full-screen rewarded video ads.
///
/// An interface rather than a direct SDK call, so the support flow can be
/// tested without a device and the app does not care whether a real ad network
/// is wired up (desktop builds have none).
///
/// Nothing touches the ad network until [prepare] is called; the app calls it
/// once at startup so a video is loaded and waiting before the support flow is
/// ever opened, and nothing thereafter loads an ad just because a dialog
/// appeared.
abstract interface class AdService {
  /// True while a rewarded ad is loaded and ready to present.
  RxBool get isReady;

  /// True while an ad request is in flight, including the SDK handshake that
  /// precedes it. Views use this to show progress instead of a dead option.
  RxBool get isLoading;

  /// Why the most recent request produced no ad, or [AdFailureReason.unknown]
  /// before any request has failed. Read it after [showRewarded] completes with
  /// [RewardedAdOutcome.unavailable].
  AdFailureReason get lastFailureReason;

  /// Initializes the SDK and starts loading an ad. Idempotent, and harmless on
  /// platforms without an ad SDK — where it simply stays idle.
  Future<void> prepare();

  /// Presents a rewarded video, completing with how the attempt ended.
  Future<RewardedAdOutcome> showRewarded();
}

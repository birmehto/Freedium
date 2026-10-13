import 'ad_service.dart';

/// Classifies an AdMob load error into the reason a support dialog should show.
///
/// The SDK hands over a platform error code and a human-readable message, and
/// whose numbers differ per platform — no fill is `3` on Android but `1` on
/// iOS, internal error is `0` on Android but `11` on iOS. So the code is read
/// against the platform that produced it, and the message is used as a second
/// signal for conditions that arrive under a generic code (a blocked hostname,
/// for instance).
AdFailureReason classifyAdFailure({
  required int code,
  required String message,
  required bool isAndroid,
}) {
  final text = message.toLowerCase();

  // A dedicated code exists only on iOS; on Android a timeout is message-only.
  if ((!isAndroid && code == 5) ||
      text.contains('timeout') ||
      text.contains('timed out')) {
    return AdFailureReason.timeout;
  }

  // The request never reached the ad server. Network error is `2` on both
  // platforms; the message catches DNS failures that arrive under another code.
  if (code == 2 || _looksLikeConnectionFailure(text)) {
    return AdFailureReason.noConnection;
  }

  // The server answered, but had nothing to serve.
  if (code == (isAndroid ? 3 : 1) ||
      (isAndroid && code == 9) || // mediation adapter did not fill
      text.contains('no fill') ||
      text.contains('no ad to show')) {
    return AdFailureReason.noFill;
  }

  // A malformed request, usually a wrong ad unit ID or a missing app ID.
  if (code == (isAndroid ? 1 : 0) ||
      code == (isAndroid ? 8 : 20) ||
      (isAndroid && (code == 10 || code == 11)) || // request ID / ad string
      text.contains('invalid request') ||
      text.contains('application identifier') ||
      text.contains('missing app id')) {
    return AdFailureReason.invalidRequest;
  }

  // The ad server itself failed to process the request.
  if (code == (isAndroid ? 0 : 3) ||
      (!isAndroid && code == 11) ||
      text.contains('internal error') ||
      text.contains('server error') ||
      text.contains('server failure')) {
    return AdFailureReason.serverError;
  }

  return AdFailureReason.unknown;
}

/// Whether [message] reads like the ad host could not be reached at all.
bool _looksLikeConnectionFailure(String message) {
  const phrases = [
    'failed to connect',
    'connecting to ad server',
    'connection refused',
    'connection reset',
    'unable to resolve host',
    'no address associated',
    'network is unreachable',
    'host is unreachable',
    'temporary failure in name resolution',
    'nodename nor servname',
    'no such host',
    'unknownhost',
    'getaddrinfo',
  ];

  return phrases.any(message.contains);
}

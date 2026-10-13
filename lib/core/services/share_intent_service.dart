import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../network/article_url.dart';
import '../storage/preferences_store.dart';
import '../utils/app_log.dart';

/// Listens for URLs shared into Freedium from other Android apps.
///
/// The service owns no UI state: it publishes the last shared URL and lets the
/// Home feature decide what to do with it.
class ShareIntentService extends GetxService {
  ShareIntentService(this._preferences);

  final PreferencesStore _preferences;

  /// Most recent URL received through a share intent.
  ///
  /// Reactive so a share that arrives while Home is already on screen is picked
  /// up without a restart. A share that arrives before Home exists stays in
  /// this field and is picked up when Home initializes.
  final RxnString incomingUrl = RxnString();

  StreamSubscription<dynamic>? _intentSub;

  Future<ShareIntentService> init() async {
    // Android is the only platform that can share into the app.
    if (!Platform.isAndroid) return this;

    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (files) {
        if (files.isNotEmpty) handleShare(files.first.path);
      },
      onError: (error, stackTrace) {
        appLog(
          'Share intent stream error: $error',
          name: 'ShareIntent',
          level: LogLevel.warning,
        );
      },
    );

    try {
      final files = await ReceiveSharingIntent.instance.getInitialMedia();
      if (files.isNotEmpty) handleShare(files.first.path);
    } catch (error) {
      appLog(
        'Could not read the initial share intent: $error',
        name: 'ShareIntent',
        level: LogLevel.warning,
      );
    } finally {
      // Cleared unconditionally, not just when a share was found. Leaving it
      // in place lets Android's re-delivery of the launch intent (see
      // [_isRedelivered]) resurrect a share that was already handled.
      try {
        await ReceiveSharingIntent.instance.reset();
      } catch (error) {
        appLog(
          'Could not reset the share intent: $error',
          name: 'ShareIntent',
          level: LogLevel.warning,
        );
      }
    }

    return this;
  }

  /// Marks the current share as handled.
  void consume() => incomingUrl.value = null;

  /// Reads [text] as a share payload and publishes the article URL in it.
  ///
  /// The single place a share is interpreted, so both the launch intent and the
  /// live stream are judged by the same rules. Public because it is also the
  /// only seam a test can reach: the platform channel it is normally called
  /// from does not exist outside a device.
  void handleShare(String? text) {
    final url = ArticleUrl.normalize(ArticleUrl.extractFirstUrl(text));
    if (url == null) return;

    // Android keeps the intent that started a task on that task, and hands it
    // back as the "initial" intent every time the task is relaunched. So after
    // Android has killed the process, relaunching the app from Recents
    // re-delivers the very share that opened it last time — which sent the
    // reader straight back into the article instead of Home. Remembering the
    // URL that was opened is what tells those two apart: a different link is a
    // new share, and the same one is the old intent coming round again.
    if (_preferences.lastSharedUrl == url) {
      appLog(
        'Ignoring a re-delivered share for an article already opened',
        name: 'ShareIntent',
      );
      return;
    }

    appLog('Received shared URL', name: 'ShareIntent');
    _preferences.lastSharedUrl = url;
    incomingUrl.value = url;
  }

  @override
  void onClose() {
    _intentSub?.cancel();
    super.onClose();
  }
}

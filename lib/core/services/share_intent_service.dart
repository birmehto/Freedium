import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../network/article_url.dart';
import '../storage/preferences_store.dart';
import '../utils/app_log.dart';

/// Listens for URLs shared into Freedium from other Android apps.
///
/// The service owns no UI state: it publishes the last shared URL and lets the
/// Home feature decide what to do with it.
class ShareIntentService {
  ShareIntentService(this._preferences);

  final PreferencesStore _preferences;

  /// Most recent URL received through a share intent.
  ///
  /// A share that arrives before Home exists stays here and is picked up when
  /// Home initializes; one that arrives while Home is on screen is heard through
  /// [addListener].
  final ValueNotifier<String?> incomingUrl = ValueNotifier<String?>(null);

  StreamSubscription<dynamic>? _intentSub;

  Future<ShareIntentService> init() async {
    // Android is the only platform that can share into the app.
    if (!Platform.isAndroid) return this;

    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (files) {
        if (files.isNotEmpty) handleShare(files.first.path);
      },
      onError: (error, stackTrace) {
        appLog('Share intent stream error: $error', name: 'ShareIntent');
      },
    );

    try {
      final files = await ReceiveSharingIntent.instance.getInitialMedia();
      if (files.isNotEmpty) {
        handleShare(files.first.path, fromLaunchIntent: true);
      }
    } catch (error) {
      appLog(
        'Could not read the initial share intent: $error',
        name: 'ShareIntent',
      );
    } finally {
      // Cleared unconditionally: Android re-delivers the launch intent after a
      // restart, and leaving it in place would resurrect an already handled
      // share.
      try {
        await ReceiveSharingIntent.instance.reset();
      } catch (error) {
        appLog('Could not reset the share intent: $error', name: 'ShareIntent');
      }
    }

    return this;
  }

  /// Marks the current share as handled.
  void consume() => incomingUrl.value = null;

  /// Reads [text] as a share payload and publishes the article URL in it.
  ///
  /// The single place a share is interpreted, so the launch intent and the live
  /// stream follow the same rules. Public as the only seam tests can reach.
  ///
  /// [fromLaunchIntent] marks a payload read from `getInitialMedia` when the
  /// process starts. Android re-delivers the intent that started a task when
  /// the task is restored from recents, so that path has to be deduplicated
  /// against the last share. A live share (`onNewIntent`, the media stream) is
  /// a fresh request even when it carries the same URL.
  void handleShare(String? text, {bool fromLaunchIntent = false}) {
    final url = ArticleUrl.normalize(ArticleUrl.extractFirstUrl(text));
    if (url == null) return;

    if (fromLaunchIntent && _preferences.lastSharedUrl == url) {
      appLog('Ignoring a re-delivered share', name: 'ShareIntent');
      return;
    }

    _preferences.lastSharedUrl = url;
    incomingUrl.value = url;
  }

  void dispose() {
    _intentSub?.cancel();
    incomingUrl.dispose();
  }
}

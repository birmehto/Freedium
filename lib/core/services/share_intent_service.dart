import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../network/article_url.dart';
import '../utils/app_log.dart';

/// Listens for URLs shared into Freedium from other Android apps.
///
/// The service owns no UI state: it publishes the last shared URL and lets the
/// Home feature decide what to do with it.
class ShareIntentService extends GetxService {
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
        if (files.isNotEmpty) _process(files.first.path);
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

      if (files.isNotEmpty) {
        _process(files.first.path);
        ReceiveSharingIntent.instance.reset();
      }
    } catch (error) {
      appLog(
        'Could not read the initial share intent: $error',
        name: 'ShareIntent',
        level: LogLevel.warning,
      );
    }

    return this;
  }

  /// Marks the current share as handled.
  void consume() => incomingUrl.value = null;

  void _process(String? text) {
    final url = ArticleUrl.normalize(ArticleUrl.extractFirstUrl(text));
    if (url == null) return;

    appLog('Received shared URL', name: 'ShareIntent');
    incomingUrl.value = url;
  }

  @override
  void onClose() {
    _intentSub?.cancel();
    super.onClose();
  }
}

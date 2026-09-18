import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../features/home/controllers/home_controller.dart';
import '../network/article_url.dart';
import '../utils/app_log.dart';

class ShareIntentService extends GetxService {
  String? pendingUrl;
  StreamSubscription? _intentSub;

  Future<ShareIntentService> init() async {
    if (!Platform.isAndroid && !Platform.isIOS) return this;

    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (files) {
        if (files.isNotEmpty) _process(files.first.path);
      },
      onError: (error) {
        appLog(
          'Share intent stream error',
          name: 'ShareIntent',
          level: LogLevel.warning,
        );
        appLog(error.toString(), name: 'ShareIntent');
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
        'Failed to read initial share intent',
        name: 'ShareIntent',
        level: LogLevel.warning,
      );
      appLog(error.toString(), name: 'ShareIntent');
    }

    return this;
  }

  void _process(String? text) {
    final url = ArticleUrl.extractFirstUrl(text);
    if (url == null) return;

    final cleanUrl = ArticleUrl.cleanUrl(url) ?? url;
    if (cleanUrl.isEmpty) return;

    if (Get.isRegistered<HomeController>()) {
      final controller = Get.find<HomeController>();
      controller.urlController.text = cleanUrl;

      WidgetsBinding.instance.addPostFrameCallback(
        (_) => controller.openArticle(),
      );
    } else {
      pendingUrl = cleanUrl;
    }
  }

  @override
  void onClose() {
    _intentSub?.cancel();
    super.onClose();
  }
}

import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../features/home/controllers/home_controller.dart';
import '../utils/app_log.dart';
import '../utils/url_validator.dart';

class ShareIntentService extends GetxService {
  String? pendingUrl;
  StreamSubscription? _intentSub;

  Future<ShareIntentService> init() async {
    if (!Platform.isAndroid && !Platform.isIOS) return this;

    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((files) {
      if (files.isNotEmpty) _process(files.first.path);
    }, onError: (error) => appLog(error.toString()));

    try {
      final files = await ReceiveSharingIntent.instance.getInitialMedia();

      if (files.isNotEmpty) {
        _process(files.first.path);
        ReceiveSharingIntent.instance.reset();
      }
    } catch (error) {
      appLog(error.toString());
    }

    return this;
  }

  void _process(String? text) {
    final url = UrlValidator.extractUrlFromText(text ?? '');
    if (url == null) return;

    final cleanUrl = UrlValidator.cleanTextiseUrl(url);
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

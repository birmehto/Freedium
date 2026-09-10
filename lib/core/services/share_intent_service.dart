import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../features/home/presentation/controllers/home_controller.dart';
import '../app/app_log.dart';
import '../utils/url_validator.dart';

class ShareIntentService extends GetxService {
  String? pendingUrl;
  StreamSubscription? _intentSub;

  Future<ShareIntentService> init() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return this;
    }

    // Handle incoming intents when app is running
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (files) {
        if (files.isNotEmpty) {
          final sharedText = files.first.path;
          _processSharedText(sharedText);
        }
      },
      onError: (err) {
        appLog(err);
      },
    );

    // Check for initial intent when app starts
    try {
      final List<SharedMediaFile> initialMedia = await ReceiveSharingIntent
          .instance
          .getInitialMedia();
      if (initialMedia.isNotEmpty) {
        final sharedText = initialMedia.first.path;
        _processSharedText(sharedText);
        ReceiveSharingIntent.instance.reset();
      }
    } catch (e, s) {
      appLog(e.toString(), stackTrace: s);
    }
    return this;
  }

  void _processSharedText(String? sharedText) {
    if (sharedText == null || sharedText.isEmpty) return;

    // Extract and clean URL
    String? url = UrlValidator.extractUrlFromText(sharedText);
    if (url != null) {
      url = UrlValidator.cleanTextiseUrl(url);
      if (url != null && url.isNotEmpty) {
        _openArticle(url);
      }
    }
  }

  void _openArticle(String url) {
    if (Get.isRegistered<HomeController>()) {
      final homeController = Get.find<HomeController>();
      homeController.urlController.text = url;
      homeController.onUrlChanged(url);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => homeController.openArticle(),
      );
    } else {
      pendingUrl = url;
    }
  }

  @override
  void onClose() {
    _intentSub?.cancel();
    super.onClose();
  }
}

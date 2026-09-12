import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/services/clipboard_service.dart';
import '../../../core/services/share_intent_service.dart';
import '../../../core/utils/app_log.dart';
import '../../../core/utils/url_validator.dart';

class HomeController extends GetxController {
  final ClipboardService _clipboardService = Get.find();

  final TextEditingController urlController = TextEditingController();
  final RxString urlText = ''.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    urlController.addListener(() {
      urlText.value = urlController.text;
    });

    // Process any shared URL received before UI was ready
    if (Get.isRegistered<ShareIntentService>()) {
      final shareService = Get.find<ShareIntentService>();
      if (shareService.pendingUrl != null) {
        final url = shareService.pendingUrl!;
        shareService.pendingUrl = null;
        urlController.text = url;
        WidgetsBinding.instance.addPostFrameCallback((_) => openArticle());
      }
    }
  }

  @override
  void onClose() {
    urlController.dispose();
    super.onClose();
  }

  bool get canOpenArticle {
    return urlText.isNotEmpty && errorMessage.isEmpty && !isLoading.value;
  }

  String? _validateUrl(String url) {
    if (url.isEmpty) return null;
    final cleaned = UrlValidator.cleanUrl(url);
    if (cleaned == null) return 'Please enter a valid URL';
    return null;
  }

  void onUrlChanged(String value) {
    errorMessage.value = _validateUrl(value.trim()) ?? '';
  }

  Future<void> pasteFromClipboard() async {
    try {
      final clipboardText = await _clipboardService.getFromClipboard();
      if (clipboardText != null && clipboardText.isNotEmpty) {
        urlController.text = clipboardText;
        onUrlChanged(clipboardText);
      }
    } catch (e) {
      M3ESnackbar.show(
        Get.context!,
        message: 'Failed to paste from clipboard: $e',
      );
    }
  }

  void clearUrl() {
    urlController.clear();
    errorMessage.value = '';
  }

  Future<void> openArticle() async {
    if (!canOpenArticle) return;

    final url = urlController.text.trim();
    final cleanedUrl = UrlValidator.cleanUrl(url);
    if (cleanedUrl == null) {
      errorMessage.value = 'Please enter a valid URL';
      return;
    }
    isLoading.value = true;
    try {
      final freediumUrl = UrlValidator.convertToFreediumUrl(cleanedUrl);
      if (freediumUrl != null) {
        await Get.toNamed(
          AppRoutes.article,
          arguments: {'url': freediumUrl, 'originalUrl': cleanedUrl},
        );
      } else {
        errorMessage.value = 'Failed to process the URL';
      }
    } catch (e) {
      appLog(e.toString());
      errorMessage.value = 'Failed to open article: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }
}

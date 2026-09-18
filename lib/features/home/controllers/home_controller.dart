import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/clipboard_service.dart';
import '../../../core/services/share_intent_service.dart';
import '../../../core/utils/app_log.dart';
import '../../../core/utils/url_validator.dart';

class HomeController extends GetxController {
  HomeController(this._clipboardService);

  final ClipboardService _clipboardService;

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
      final exception = AppException.from(e, context: 'pasteFromClipboard');
      appLog(exception.toString(), name: 'Home', level: LogLevel.warning);
      M3ESnackbar.show(
        Get.context!,
        message: 'Failed to paste from clipboard: ${exception.userMessage}',
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
      errorMessage.value = AppException.invalidUrl().userMessage;
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
        errorMessage.value = AppException.invalidUrl().userMessage;
      }
    } catch (e, stackTrace) {
      final exception = AppException.from(e, context: 'openArticle');
      appLog(exception.toString(), name: 'Home', level: LogLevel.error);
      appLog(stackTrace.toString(), name: 'Home');
      errorMessage.value = exception.userMessage;
    } finally {
      isLoading.value = false;
    }
  }
}

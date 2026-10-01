import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/article_url.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/clipboard_service.dart';
import '../../../core/services/share_intent_service.dart';
import '../../../core/utils/app_log.dart';
import '../../article/models/article_request.dart';

class HomeController extends GetxController {
  HomeController(this._clipboardService, this._shareIntentService);

  final ClipboardService _clipboardService;
  final ShareIntentService _shareIntentService;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController urlController = TextEditingController();
  final FocusNode urlFocusNode = FocusNode();

  /// Reactive view of [urlController] text, for enabling the submit button.
  final RxString urlText = ''.obs;

  /// Non-empty when an action failed; the field validator handles bad input.
  final RxString errorMessage = ''.obs;

  final RxBool isLoading = false.obs;

  late final Worker _shareWorker;

  @override
  void onInit() {
    super.onInit();

    urlController.addListener(_onUrlTextChanged);

    _shareWorker = ever(_shareIntentService.incomingUrl, _openSharedUrl);

    // A share received before Home existed is still waiting in the service.
    final pending = _shareIntentService.incomingUrl.value;

    if (pending != null) {
      _openSharedUrl(pending);
    }
  }

  @override
  void onClose() {
    _shareWorker.dispose();
    urlController.removeListener(_onUrlTextChanged);
    urlController.dispose();
    urlFocusNode.dispose();

    super.onClose();
  }

  bool get canOpenArticle {
    final url = urlText.value.trim();

    return url.isNotEmpty &&
        ArticleUrl.isValid(url) &&
        ArticleUrl.isMedium(url) &&
        errorMessage.isEmpty &&
        !isLoading.value;
  }

  void _onUrlTextChanged() {
    urlText.value = urlController.text;
  }

  void onUrlChanged(String value) {
    errorMessage.value = '';
  }

  void submit() {
    urlFocusNode.unfocus();

    final isValid = formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    openArticle();
  }

  Future<void> pasteFromClipboard() async {
    try {
      final clipboardText = await _clipboardService.getFromClipboard();

      if (clipboardText == null || clipboardText.isEmpty) {
        return;
      }

      urlController.text = clipboardText.trim();
      onUrlChanged(clipboardText);
    } catch (error) {
      final exception = AppException.from(error, context: 'pasteFromClipboard');

      appLog(exception.toString(), name: 'Home', level: LogLevel.warning);

      _showMessage('Failed to paste from clipboard: ${exception.userMessage}');
    }
  }

  void clearUrl() {
    urlController.clear();
    errorMessage.value = '';
  }

  Future<void> openArticle() async {
    if (!canOpenArticle) return;

    final request = ArticleRequest.parse(urlController.text);

    if (!request.isValid) {
      errorMessage.value = AppException.invalidUrl().userMessage;
      return;
    }

    isLoading.value = true;

    try {
      await Get.toNamed(AppRoutes.article, arguments: request);
    } catch (error, stackTrace) {
      final exception = AppException.from(error, context: 'openArticle');

      appLog('$exception\n$stackTrace', name: 'Home', level: LogLevel.error);

      errorMessage.value = exception.userMessage;
    } finally {
      isLoading.value = false;
    }
  }

  void _openSharedUrl(String? url) {
    if (url == null) return;

    // A share is an explicit request to read this article, so the field is
    // filled and opened directly. A failure left over from earlier input would
    // otherwise block the request that is being made right now.
    errorMessage.value = '';
    urlController.text = url;
    _shareIntentService.consume();

    WidgetsBinding.instance.addPostFrameCallback((_) => submit());
  }

  /// Shows a transient message, if a context is available at that moment.
  void _showMessage(String message) {
    if (Get.context case final context?) {
      M3ESnackbar.show(context, message: message);
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart'
    show FocusNode, FormState, GlobalKey, TextEditingController, WidgetsBinding;

import '../../../core/errors/app_exception.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../core/network/article_url.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/utils/app_log.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../article/models/article_request.dart';
import '../../article/views/article_page.dart';

/// The URL field's observable state. Text editing itself stays in the
/// [TextEditingController] so the platform keeps its native behavior.
class HomeState {
  const HomeState({
    this.urlText = '',
    this.errorMessage = '',
    this.isLoading = false,
  });

  final String urlText;
  final String errorMessage;
  final bool isLoading;

  HomeState copyWith({String? urlText, String? errorMessage, bool? isLoading}) {
    return HomeState(
      urlText: urlText ?? this.urlText,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final homeControllerProvider = NotifierProvider<HomeController, HomeState>(
  HomeController.new,
);

class HomeController extends Notifier<HomeState> {
  final formKey = GlobalKey<FormState>();
  final urlController = TextEditingController();
  final urlFocusNode = FocusNode();

  @override
  HomeState build() {
    final share = ref.watch(shareIntentServiceProvider);
    final listener = share.incomingUrl;

    urlController.addListener(_onUrlTextChanged);
    listener.addListener(_onShareChanged);
    ref.onDispose(() {
      listener.removeListener(_onShareChanged);
      urlController.removeListener(_onUrlTextChanged);
      urlController.dispose();
      urlFocusNode.dispose();
    });

    final pending = listener.value;
    if (pending != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openSharedUrl(pending),
      );
    }

    return const HomeState();
  }

  bool get canOpenArticle {
    final url = state.urlText.trim();
    return url.isNotEmpty &&
        ArticleUrl.isValid(url) &&
        ArticleUrl.isMedium(url) &&
        state.errorMessage.isEmpty &&
        !state.isLoading;
  }

  void _onUrlTextChanged() {
    state = state.copyWith(urlText: urlController.text);
  }

  void _onShareChanged() {
    final url = ref.read(shareIntentServiceProvider).incomingUrl.value;
    if (url != null) _openSharedUrl(url);
  }

  void onUrlChanged(String _) {
    state = state.copyWith(errorMessage: '');
  }

  void submit() {
    urlFocusNode.unfocus();
    if (formKey.currentState?.validate() ?? false) openArticle();
  }

  Future<void> pasteFromClipboard() async {
    try {
      final text = await ref.read(clipboardServiceProvider).getFromClipboard();
      if (text == null || text.isEmpty) {
        AppSnackbar.message('Clipboard is empty');
        return;
      }

      urlController.text = text.trim();
      onUrlChanged(text);
    } catch (error) {
      final exception = AppException.from(error, context: 'pasteFromClipboard');
      appLog(exception.toString(), name: 'Home', level: LogLevel.warning);
      AppSnackbar.message(
        'Failed to paste from clipboard: ${exception.userMessage}',
      );
    }
  }

  void clearUrl() {
    urlController.clear();
    state = const HomeState();
  }

  Future<void> openArticle() async {
    if (!canOpenArticle) return;

    final request = ArticleRequest.parse(urlController.text);
    if (!request.isValid) {
      state = state.copyWith(
        errorMessage: AppException.invalidUrl().userMessage,
      );
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      final route = pushPage(ArticlePage(request: request));
      // The route's future completes only when the reader is popped. Keeping
      // the form disabled until then would reject a share that arrives while
      // an article is already open.
      state = state.copyWith(isLoading: false);
      await route;
      urlController.clear();
      state = const HomeState();
    } catch (error, stackTrace) {
      final exception = AppException.from(error, context: 'openArticle');
      appLog('$exception\n$stackTrace', name: 'Home', level: LogLevel.error);
      state = state.copyWith(errorMessage: exception.userMessage);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// A share is an explicit request to read the article: fill the field and open
  /// it, clearing any error left over from earlier input.
  void _openSharedUrl(String url) {
    state = state.copyWith(urlText: url, errorMessage: '');
    urlController.text = url;
    ref.read(shareIntentServiceProvider).consume();
    WidgetsBinding.instance.addPostFrameCallback((_) => submit());
  }
}

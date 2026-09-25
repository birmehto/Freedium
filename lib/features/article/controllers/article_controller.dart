import 'dart:async';
import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/reader_theme.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/article_resolver.dart';
import '../../../core/network/article_url.dart';
import '../../../core/services/clipboard_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/utils/app_log.dart';
import '../../favorites/models/favorite_article.dart';
import '../../settings/models/reader_settings.dart';
import '../models/article_meta.dart';

class ArticleController extends GetxController {
  ArticleController(
    this._clipboard,
    this._storage,
    this._theme, {
    ArticleResolver? resolver,
  }) : _resolver = resolver ?? ArticleResolver();

  final ClipboardService _clipboard;
  final StorageService _storage;
  final ThemeService _theme;
  final ArticleResolver _resolver;

  // State
  final currentUrl = ''.obs;
  final originalUrl = ''.obs;
  final savedHtml = ''.obs;
  final errorMessage = ''.obs;

  final isOfflineCopy = false.obs;
  final isLoading = true.obs;
  final isInitialLoad = true.obs;
  final loadingProgress = 0.0.obs;

  final articleTitle = ''.obs;
  final articleAuthor = ''.obs;
  final articlePublication = ''.obs;
  final publishedAt = Rxn<DateTime>();
  final wordCount = 0.obs;
  final readingTime = 0.obs;

  final isFavorite = false.obs;
  final readingSettings = const ReaderSettings().obs;

  final findQuery = ''.obs;
  final findMatchCount = 0.obs;
  final findMatchIndex = 0.obs;

  InAppWebViewController? webViewController;
  FindInteractionController? findController;

  Timer? _loadingTimer;

  bool get isDarkMode => _theme.isDarkMode.value;

  double get fontSize => readingSettings.value.fontSize;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments as Map<String, dynamic>?;
    final rawUrl = args?['url'] as String?;
    final original = args?['originalUrl'] as String?;
    final data = args?['articleData'] as Map<String, dynamic>?;

    final url = ArticleUrl.canonicalize(original ?? rawUrl ?? '');

    if (url.isEmpty) {
      errorMessage.value = AppException.invalidUrl().userMessage;
      isLoading.value = false;
      return;
    }

    originalUrl.value = url;
    isOfflineCopy.value = data != null;

    _loadSavedArticle(data, url);
    _loadPreferences(url);

    currentUrl.value = isOfflineCopy.value
        ? url
        : _resolver.resolve(url) ?? url;

    _startLoadingTimer();

    findController = FindInteractionController(
      onFindResultReceived: (_, active, matches, _) {
        findMatchCount.value = matches;
        findMatchIndex.value = matches > 0 ? active + 1 : 0;
      },
    );

    _setupReactions();
  }

  void _loadSavedArticle(Map<String, dynamic>? data, String url) {
    if (data?['html'] is! String) return;

    savedHtml.value = data!['html'] as String;

    articleTitle.value = (data['title'] as String?)?.isNotEmpty == true
        ? data['title'] as String
        : _titleFromUrl(url);

    articleAuthor.value = data['author'] as String? ?? '';
    articlePublication.value = data['publication'] as String? ?? '';
  }

  void _loadPreferences(String url) {
    final preferences = _storage.preferences;

    readingSettings.value = preferences.readerSettings;

    _resolver.setPreferred(preferences.preferredMirror);

    _resolver.autoFallback = preferences.autoFallback;

    isFavorite.value = _storage.library.isFavorite(url);

    final cached = _storage.library.cachedMeta[url];

    if (cached != null) {
      articleTitle.value = cached.title;
      articleAuthor.value = cached.author ?? '';
      articlePublication.value = cached.publication ?? '';
      wordCount.value = cached.wordCount;
      readingTime.value = cached.readingTimeMinutes;
      publishedAt.value = cached.publishedAt;
    } else if (articleTitle.value.isEmpty) {
      articleTitle.value = _titleFromUrl(url);
    }
  }

  void _setupReactions() {
    ever(_theme.isDarkMode, (_) => injectCustomCSS());

    ever(readingSettings, (_) {
      _storage.preferences.readerSettings = readingSettings.value;

      injectCustomCSS();
    });
  }

  // ---------------------------------------------------------------------------
  // WebView
  // ---------------------------------------------------------------------------

  void setWebViewController(InAppWebViewController controller) {
    webViewController = controller;
  }

  void onPageLoaded() {
    _stopLoading();

    unawaited(_extractMetadata());
    _resolver.reportSuccess(_resolver.lastSourceId ?? '');
  }

  void onPageError(String message) {
    _stopLoading();

    errorMessage.value = message;
    loadingProgress.value = 0;
    isLoading.value = false;
    isInitialLoad.value = false;

    _resolver.reportFailure(_resolver.lastSourceId ?? '');
  }

  void updateProgress(double progress) {
    loadingProgress.value = progress / 100;
  }

  void requestRefresh() {
    errorMessage.value = '';
    isLoading.value = true;
    loadingProgress.value = 0;
    _startLoadingTimer();

    unawaited(webViewController?.reload());
  }

  // ---------------------------------------------------------------------------
  // Reader
  // ---------------------------------------------------------------------------

  void updateReaderSettings(ReaderSettings settings) {
    readingSettings.value = settings;
  }

  void setFontSize(double size) {
    final value = size.clamp(
      ReaderSettings.kMinFontSize,
      ReaderSettings.kMaxFontSize,
    );

    updateReaderSettings(readingSettings.value.copyWith(fontSize: value));

    _storage.preferences.fontSize = value;
  }

  Future<void> injectCustomCSS() async {
    final controller = webViewController;

    if (isClosed || controller == null) return;

    final css = ReaderTheme.getCss(
      settings: readingSettings.value,
      systemDark: isDarkMode,
    );

    try {
      await controller.evaluateJavascript(
        source:
            '''
          document.getElementById(
            '${ReaderTheme.customCssId}'
          )?.remove();

          var style = document.createElement('style');
          style.id = '${ReaderTheme.customCssId}';
          style.textContent = `${css.replaceAll('`', r'\`')}`;

          document.head.appendChild(style);
        ''',
      );
    } catch (e) {
      appLog('Error injecting CSS', name: 'Reader', level: LogLevel.warning);
      appLog(e.toString(), name: 'Reader');
    }
  }

  // ---------------------------------------------------------------------------
  // Article
  // ---------------------------------------------------------------------------

  Future<void> _extractMetadata() async {
    final controller = webViewController;

    if (isClosed || controller == null) return;

    try {
      final result = await controller.evaluateJavascript(
        source: ReaderTheme.extractMetaJs,
      );

      if (result is! String || result.isEmpty) return;

      final meta = ArticleMeta.fromJson(
        jsonDecode(result) as Map<String, dynamic>?,
      );

      if (meta.title.isEmpty) return;

      articleTitle.value = meta.title;
      articleAuthor.value = meta.author ?? '';
      articlePublication.value = meta.publication ?? '';
      wordCount.value = meta.wordCount;
      readingTime.value = meta.readingTimeMinutes;
      publishedAt.value = meta.publishedAt;

      _storage.library.cacheMeta(originalUrl.value, meta);
    } catch (e) {
      appLog(
        'Failed to extract metadata',
        name: 'Reader',
        level: LogLevel.warning,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> openInBrowser() async {
    final uri = Uri.tryParse(originalUrl.value);

    if (uri == null) {
      errorMessage.value = 'Invalid URL';
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> copyLink() {
    return _clipboard.copyToClipboard(originalUrl.value);
  }

  Future<void> shareArticle() async {
    final url = originalUrl.value;

    if (url.isEmpty) return;

    await SharePlus.instance.share(
      ShareParams(
        title: 'Share from Freedium',
        text: '${articleTitle.value}\n\n$url',
      ),
    );
  }

  Future<void> toggleFavorite() async {
    final url = originalUrl.value.isNotEmpty
        ? originalUrl.value
        : currentUrl.value;

    if (url.isEmpty) return;

    if (isFavorite.value) {
      await _storage.library.removeFromFavorites(url);
    } else {
      await _storage.library.addToFavorites(
        FavoriteArticle(
          title: articleTitle.value,
          url: url,
          visitedAt: DateTime.now(),
          author: articleAuthor.value.isNotEmpty ? articleAuthor.value : null,
          domain: articleDomain,
        ).toJson(),
      );
    }
    isFavorite.toggle();
  }

  String get articleDomain {
    final host = Uri.tryParse(originalUrl.value)?.host ?? '';

    return host.startsWith('www.') ? host.substring(4) : host;
  }

  String _titleFromUrl(String url) {
    final segments = Uri.tryParse(url)?.pathSegments;

    if (segments == null || segments.isEmpty) {
      return 'Article';
    }

    return segments.last
        .replaceAll('-', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  void _startLoadingTimer() {
    _loadingTimer?.cancel();

    _loadingTimer = Timer(AppConstants.webViewTimeout, () {
      if (isLoading.value) {
        onPageError(
          'Loading timeout. Please check your connection and try again.',
        );
      }
    });
  }

  void _stopLoading() {
    _loadingTimer?.cancel();
    _loadingTimer = null;

    isLoading.value = false;
    isInitialLoad.value = false;
    loadingProgress.value = 1;
  }

  @override
  void onClose() {
    _loadingTimer?.cancel();
    findController?.dispose();
    super.onClose();
  }

  void handleServerError(int statusCode) {
    onPageError(switch (statusCode) {
      502 => 'Bad Gateway (502). Server unavailable.',
      503 => 'Service Unavailable (503).',
      _ => 'Server error ($statusCode)',
    });
  }
}

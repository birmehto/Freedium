import 'dart:async';
import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
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
    this._clipboardService,
    this._storage,
    this._themeService, {
    ArticleResolver? resolver,
  }) : _resolver = resolver ?? ArticleResolver();

  final ClipboardService _clipboardService;
  final StorageService _storage;
  final ThemeService _themeService;
  final ArticleResolver _resolver;

  // Navigation / loading
  final currentUrl = ''.obs;
  final originalUrl = ''.obs;
  final savedHtml = ''.obs;
  final isOfflineCopy = false.obs;
  final errorMessage = ''.obs;
  final isLoading = true.obs;
  final isInitialLoad = true.obs;
  final loadingProgress = 0.0.obs;

  // Extracted metadata
  final articleTitle = ''.obs;
  final articleAuthor = ''.obs;
  final articlePublication = ''.obs;
  final publishedAt = Rxn<DateTime>();
  final wordCount = 0.obs;
  final readingTime = 0.obs;

  // Library state
  final isFavorite = false.obs;

  // Reader preferences
  final readingSettings = const ReaderSettings().obs;

  // Find in page
  final isFindActive = false.obs;
  final findQuery = ''.obs;
  final findMatchCount = 0.obs;
  final findMatchIndex = 0.obs;

  InAppWebViewController? webViewController;
  FindInteractionController? findController;

  double? _contentHeight;
  double? _viewportHeight;
  Timer? _loadingTimer;

  bool get isDarkMode => _themeService.isDarkMode.value;

  bool get readerIsDark =>
      ReaderTheme.readerIsDark(readingSettings.value, systemDark: isDarkMode);

  double get fontSize => readingSettings.value.fontSize;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments as Map<String, dynamic>?;
    final raw = args?['url'] as String?;
    final original = args?['originalUrl'] as String?;
    final data = args?['articleData'] as Map<String, dynamic>?;

    final canonical = ArticleUrl.canonicalize(original ?? raw ?? '');
    if (canonical.isEmpty || (raw == null && original == null)) {
      errorMessage.value = AppException.invalidUrl().userMessage;
      isLoading.value = false;
      return;
    }

    originalUrl.value = canonical;
    isOfflineCopy.value = data != null;
    if (data?['html'] is String) {
      savedHtml.value = data!['html'] as String;
      articleTitle.value = (data['title'] as String?)?.isNotEmpty == true
          ? data['title'] as String
          : _titleFromUrl(canonical);
      articleAuthor.value = (data['author'] as String?) ?? '';
      articlePublication.value = (data['publication'] as String?) ?? '';
    }

    // Reader preferences + mirror sources
    readingSettings.value = _storage.preferences.readerSettings;
    _resolver.setPreferred(_storage.preferences.preferredMirror);
    _resolver.autoFallback = _storage.preferences.autoFallback;

    isFavorite.value = _storage.library.isFavorite(canonical);

    // Pre-fill metadata from cache
    final cached = _storage.library.cachedMeta[canonical];
    if (cached != null) {
      articleTitle.value = cached.title;
      articleAuthor.value = cached.author ?? '';
      articlePublication.value = cached.publication ?? '';
      wordCount.value = cached.wordCount;
      readingTime.value = cached.readingTimeMinutes;
      publishedAt.value = cached.publishedAt;
    } else if (articleTitle.isEmpty) {
      articleTitle.value = _titleFromUrl(canonical);
    }

    if (isOfflineCopy.value) {
      currentUrl.value = canonical;
      _startLoadingTimer();
    } else {
      currentUrl.value = _resolver.resolve(canonical) ?? canonical;
      _startLoadingTimer();
    }

    findController = FindInteractionController(
      onFindResultReceived: (controller, active, matches, isDoneCounting) {
        findMatchCount.value = matches;
        if (matches > 0) findMatchIndex.value = active + 1;
      },
    );

    _setupReactions();
  }

  void _setupReactions() {
    ever(_themeService.isDarkMode, (_) {
      if (!isClosed) injectCustomCSS();
    });
    ever(readingSettings, (_) {
      if (!isClosed) {
        _storage.preferences.readerSettings = readingSettings.value;
        injectCustomCSS();
      }
    });
  }

  // ────────────────────────────── load lifecycle ──────────────────────

  void onPageLoaded() {
    _cancelLoadingTimer();
    isLoading.value = false;
    isInitialLoad.value = false;
    loadingProgress.value = 1.0;
    unawaited(_extractMetadata());
    unawaited(_refreshLayoutMetrics());
    _resolver.reportSuccess(_resolver.lastSourceId ?? '');
  }

  void onPageError(String message) {
    _cancelLoadingTimer();
    errorMessage.value = message;
    isLoading.value = false;
    isInitialLoad.value = false;
    loadingProgress.value = 0.0;
    _resolver.reportFailure(_resolver.lastSourceId ?? '');
  }

  Future<void> _extractMetadata() async {
    if (isClosed || webViewController == null) return;
    try {
      final result = await webViewController?.evaluateJavascript(
        source: ReaderTheme.extractMetaJs,
      );
      if (result is String && result.isNotEmpty) {
        final meta = ArticleMeta.fromJson(
          jsonDecode(result) as Map<String, dynamic>?,
        );
        if (meta.title.isNotEmpty) {
          articleTitle.value = meta.title;
          articleAuthor.value = meta.author ?? '';
          articlePublication.value = meta.publication ?? '';
          wordCount.value = meta.wordCount;
          readingTime.value = meta.readingTimeMinutes;
          publishedAt.value = meta.publishedAt;
          _storage.library.cacheMeta(originalUrl.value, meta);
        }
      }
    } catch (e) {
      appLog(
        'Failed to extract metadata',
        name: 'Reader',
        level: LogLevel.warning,
      );
      appLog(e.toString(), name: 'Reader');
    }
  }

  // ─────────────────────────── layout metrics ─────────────────────────

  Future<void> _refreshLayoutMetrics() async {
    if (isClosed || webViewController == null) return;

    try {
      final result = await webViewController?.evaluateJavascript(
        source: '''
        (function() {
          var se = document.scrollingElement || document.documentElement;
          var h = se.scrollHeight || 0;
          var bodyH = document.body ? document.body.scrollHeight : 0;
          if (bodyH > h) h = bodyH;
          return JSON.stringify({
            h: h,
            v: window.innerHeight || 0
          });
        })();
      ''',
      );
      if (result is String && result.isNotEmpty) {
        final data = jsonDecode(result) as Map<String, dynamic>;
        _contentHeight = (data['h'] as num?)?.toDouble();
        _viewportHeight = (data['v'] as num?)?.toDouble();
      }

      if ((_contentHeight ?? 0) <= (_viewportHeight ?? 0)) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!isClosed) unawaited(_refreshLayoutMetrics());
        });
      }
    } catch (e) {
      appLog(
        'Failed to refresh layout metrics',
        name: 'Reader',
        level: LogLevel.warning,
      );
      appLog(e.toString(), name: 'Reader');
    }
  }

  // ─────────────────────────── mirror fail-over ───────────────────────

  void requestRefresh() {
    errorMessage.value = '';
    isLoading.value = true;
    loadingProgress.value = 0.0;
    _startLoadingTimer();
    unawaited(webViewController?.reload());
  }

  void tryNextMirror() {
    if (isOfflineCopy.value) return;
    final next = _resolver.nextFallback();
    if (next == null) {
      onPageError('All mirror sources are unavailable right now.');
      return;
    }
    currentUrl.value = next;
    errorMessage.value = '';
    isLoading.value = true;
    isInitialLoad.value = true;
    loadingProgress.value = 0.0;
    _startLoadingTimer();
    unawaited(
      webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(next))),
    );
  }

  // ─────────────────────────── reader appearance ──────────────────────

  void updateReaderSettings(ReaderSettings settings) {
    readingSettings.value = settings;
  }

  void incrementFontSize() {
    setFontSize(fontSize + ReaderSettings.kFontSizeStep);
  }

  void decrementFontSize() {
    setFontSize(fontSize - ReaderSettings.kFontSizeStep);
  }

  void setFontSize(double size) {
    final clamped = size.clamp(
      ReaderSettings.kMinFontSize,
      ReaderSettings.kMaxFontSize,
    );
    updateReaderSettings(readingSettings.value.copyWith(fontSize: clamped));
    _storage.preferences.fontSize = clamped;
  }

  void resetFontSize() {
    setFontSize(ReaderSettings.kDefaultFontSize);
  }

  Future<void> injectCustomCSS() async {
    if (isClosed || webViewController == null) return;

    final css = ReaderTheme.getCss(
      settings: readingSettings.value,
      systemDark: isDarkMode,
    );

    try {
      await webViewController?.evaluateJavascript(
        source:
            '''
        var existingStyle = document.getElementById('${ReaderTheme.customCssId}');
        if (existingStyle) {
          existingStyle.remove();
        }

        var style = document.createElement('style');
        style.id = '${ReaderTheme.customCssId}';
        style.innerHTML = `$css`;
        document.head.appendChild(style);
      ''',
      );
      unawaited(_refreshLayoutMetrics());
    } catch (e) {
      appLog('Error injecting CSS', name: 'Reader', level: LogLevel.warning);
      appLog(e.toString(), name: 'Reader');
    }
  }

  // ─────────────────────────── actions ────────────────────────────────

  Future<void> openInBrowser() async {
    if (originalUrl.isEmpty) return;
    final uri = Uri.tryParse(originalUrl.value);
    if (uri == null) {
      errorMessage.value = 'Invalid URL';
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> copyLink() async {
    if (originalUrl.isEmpty) return;
    await _clipboardService.copyToClipboard(originalUrl.value);
  }

  Future<void> toggleFavorite() async {
    final url = originalUrl.value.isNotEmpty
        ? originalUrl.value
        : currentUrl.value;
    if (url.isEmpty) return;

    if (isFavorite.value) {
      await _storage.library.removeFromFavorites(url);
      isFavorite.value = false;
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
      isFavorite.value = true;
    }
  }

  String get articleDomain {
    final uri = Uri.tryParse(originalUrl.value);
    if (uri != null && uri.host.isNotEmpty) {
      String host = uri.host;
      if (host.startsWith('www.')) host = host.substring(4);
      return host;
    }
    return '';
  }

  String _titleFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last
          .replaceAll('-', ' ')
          .split(' ')
          .map(
            (word) => word.isNotEmpty
                ? '${word[0].toUpperCase()}${word.substring(1)}'
                : word,
          )
          .join(' ');
    }
    return 'Article';
  }

  // ─────────────────────────── find in page ───────────────────────────

  void startFind() {
    isFindActive.value = true;
  }

  void onFindQueryChanged(String query) {
    findQuery.value = query;
    unawaited(
      findController?.findAll(find: query.trim().isEmpty ? null : query.trim()),
    );
  }

  void findNext(bool forward) {
    unawaited(findController?.findNext(forward: forward));
  }

  void closeFind() {
    findQuery.value = '';
    findMatchCount.value = 0;
    findMatchIndex.value = 0;
    isFindActive.value = false;
    unawaited(findController?.clearMatches());
  }

  // ─────────────────────────── timers / teardown ──────────────────────

  void _startLoadingTimer() {
    _cancelLoadingTimer();
    _loadingTimer = Timer(AppConstants.webViewTimeout, () {
      if (isLoading.value) {
        onPageError(
          'Loading timeout. Please check your connection and try again.',
        );
      }
    });
  }

  void _cancelLoadingTimer() {
    _loadingTimer?.cancel();
    _loadingTimer = null;
  }

  @override
  void onClose() {
    _cancelLoadingTimer();
    findController?.dispose();
    super.onClose();
  }

  void setWebViewController(InAppWebViewController controller) {
    webViewController = controller;
  }

  void handleServerError(int statusCode) {
    String errorMsg = 'Server error ($statusCode)';
    if (statusCode == 502) errorMsg = 'Bad Gateway (502). Server unavailable.';
    if (statusCode == 503) errorMsg = 'Service Unavailable (503).';
    onPageError(errorMsg);
  }

  void updateProgress(double progress) {
    loadingProgress.value = progress / 100.0;
  }
}

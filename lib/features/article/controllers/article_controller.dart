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
import '../models/article_request.dart';

/// Owns the state of one open article: the loaded URL, extracted metadata,
/// reader typography, favorite status and find-in-article.
class ArticleController extends GetxController {
  ArticleController(
    this._clipboard,
    this._storage,
    this._theme,
    this._resolver,
  );

  final ClipboardService _clipboard;
  final StorageService _storage;
  final ThemeService _theme;
  final ArticleResolver _resolver;

  // ─────────────────────────────── state ────────────────────────────────

  /// URL currently loaded in the WebView (a mirror-proxied URL).
  final currentUrl = ''.obs;

  /// Canonical URL of the article on the publisher's site.
  final originalUrl = ''.obs;

  final errorMessage = ''.obs;

  final isLoading = true.obs;
  final isInitialLoad = true.obs;
  final loadingProgress = 0.0.obs;

  final articleTitle = ''.obs;
  final articleAuthor = ''.obs;
  final articlePublication = ''.obs;
  final publishedAt = Rxn<DateTime>();
  final wordCount = 0.obs;
  final readingTime = 0.obs;

  final readingSettings = const ReaderSettings().obs;

  InAppWebViewController? webViewController;

  Timer? _loadingTimer;
  final List<Worker> _workers = [];

  /// Mirrors tried for the current article, newest first. Backs the reader's
  /// "switch source" affordance.
  final RxList<String> attemptedMirrors = <String>[].obs;

  // ────────────────────────────── derived ────────────────────────────────

  bool get isDarkMode => _theme.isDarkMode.value;

  double get fontSize => readingSettings.value.fontSize;

  /// Derived from the library store, so there is only one favorites state.
  bool get isFavorite => _storage.library.isFavorite(originalUrl.value);

  String get articleDomain => ArticleUrl.hostOf(originalUrl.value) ?? '';

  /// Hosts the reader may navigate to: every configured mirror plus the host
  /// that is currently loaded. Anything else is treated as an off-site link and
  /// handed to the browser instead of being silently cancelled.
  Set<String> get allowedNavigationHosts => {
    for (final source in _resolver.sources) source.host.toLowerCase(),
    if (Uri.tryParse(currentUrl.value)?.host case final host?)
      host.toLowerCase(),
  };

  // ───────────────────────────── lifecycle ───────────────────────────────

  @override
  void onInit() {
    super.onInit();

    final request = ArticleRequest.fromArguments(Get.arguments);

    if (!request.isValid) {
      errorMessage.value = AppException.invalidUrl().userMessage;
      isLoading.value = false;
      return;
    }

    final url = request.sourceUrl;
    originalUrl.value = url;

    _loadPreferences(url);
    _startLoading(request.url);

    _setupReactions();
  }

  @override
  void onClose() {
    _loadingTimer?.cancel();

    for (final worker in _workers) {
      worker.dispose();
    }
    _workers.clear();

    super.onClose();
  }

  void _loadPreferences(String url) {
    final preferences = _storage.preferences;

    readingSettings.value = preferences.readerSettings;

    _resolver.setPreferred(preferences.preferredMirror);
    _resolver.autoFallback = preferences.autoFallback;

    final cached = _storage.library.metaFor(url);
    if (cached != null) {
      articleTitle.value = cached.title;
      articleAuthor.value = cached.author ?? '';
      articlePublication.value = cached.publication ?? '';
      wordCount.value = cached.wordCount;
      readingTime.value = cached.readingTimeMinutes;
      publishedAt.value = cached.publishedAt;
    } else {
      articleTitle.value = _titleFromUrl(url);
    }
  }

  void _setupReactions() {
    // Worker-backed reactions must be disposed; an untracked `ever` would keep
    // firing after the reader is closed.
    _workers.add(ever(_theme.isDarkMode, (_) => injectCustomCSS()));

    _workers.add(
      ever(readingSettings, (settings) {
        _storage.preferences.readerSettings = settings;
        injectCustomCSS();
      }),
    );
  }

  void _startLoading(String url) {
    final resolved = _resolver.resolve(url);
    if (resolved != null) attemptedMirrors.add(resolved);

    currentUrl.value = resolved ?? url;
    _startLoadingTimer();
  }

  // ────────────────────────────── WebView ────────────────────────────────

  void setWebViewController(InAppWebViewController controller) {
    webViewController = controller;
  }

  void onPageLoaded() {
    _stopLoading();
    _resolver.reportSuccess();

    unawaited(_extractMetadata());
  }

  void onPageError(String message) {
    _stopLoading();

    _resolver.reportFailure();

    // Try the next mirror before surfacing the failure: a single dead backend
    // should not end the reading session.
    final fallback = _resolver.nextFallback();
    if (fallback != null) {
      attemptedMirrors.add(fallback);
      errorMessage.value = '';
      isLoading.value = true;
      _startLoadingTimer();
      unawaited(_loadUrl(fallback));
      return;
    }

    errorMessage.value = message;
    loadingProgress.value = 0;
    isLoading.value = false;
    isInitialLoad.value = false;
  }

  void updateProgress(double progress) {
    loadingProgress.value = progress / 100;
  }

  Future<void> requestRefresh() async {
    errorMessage.value = '';
    isLoading.value = true;
    loadingProgress.value = 0;
    _startLoadingTimer();

    await webViewController?.reload();
  }

  /// Handles the HTTP status codes a mirror can answer with.
  void handleServerError(int statusCode) {
    onPageError(switch (statusCode) {
      502 => 'Bad Gateway (502). Server unavailable.',
      503 => 'Service Unavailable (503).',
      _ => 'Server error ($statusCode)',
    });
  }

  Future<void> _loadUrl(String url) async {
    if (webViewController == null) {
      // The WebView is not mounted yet; the initial load uses `initialUrlRequest`.
      currentUrl.value = url;
      return;
    }

    await webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  // ─────────────────────────────── reader ────────────────────────────────

  void updateReaderSettings(ReaderSettings settings) {
    readingSettings.value = settings;
  }

  void setFontSize(double size) {
    updateReaderSettings(
      readingSettings.value.copyWith(
        fontSize: size.clamp(
          ReaderSettings.kMinFontSize,
          ReaderSettings.kMaxFontSize,
        ),
      ),
    );
  }

  /// Re-applies typography and color scheme to the loaded document.
  Future<void> injectCustomCSS() async {
    final controller = webViewController;
    if (isClosed || controller == null) return;

    final css = ReaderTheme.getCss(
      settings: readingSettings.value,
      systemDark: isDarkMode,
    );

    try {
      await controller.evaluateJavascript(
        source: ReaderTheme.injectCssScript(css),
      );
    } catch (error) {
      appLog(
        'Could not inject CSS: $error',
        name: 'Reader',
        level: LogLevel.warning,
      );
    }
  }

  // ─────────────────────────────── article ───────────────────────────────

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

      await _storage.library.cacheMeta(originalUrl.value, meta);
    } catch (error) {
      appLog(
        'Could not extract metadata: $error',
        name: 'Reader',
        level: LogLevel.warning,
      );
    }
  }

  // ─────────────────────────────── actions ──────────────────────────────

  Future<void> openInBrowser() async {
    final uri = Uri.tryParse(originalUrl.value);
    if (uri == null || originalUrl.value.isEmpty) {
      errorMessage.value = AppException.invalidUrl().userMessage;
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> copyLink() => _clipboard.copyToClipboard(originalUrl.value);

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
    final url = originalUrl.value;
    if (url.isEmpty) return;

    final article = FavoriteArticle(
      title: articleTitle.value,
      url: url,
      visitedAt: DateTime.now(),
      author: articleAuthor.value.isEmpty ? null : articleAuthor.value,
      domain: articleDomain.isEmpty ? null : articleDomain,
    );

    await _storage.library.toggleFavorite(article);
  }

  String _titleFromUrl(String url) {
    final segments = Uri.tryParse(url)?.pathSegments;
    if (segments == null || segments.isEmpty) return 'Article';

    return segments.last
        .replaceAll('-', ' ')
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .join(' ');
  }

  // ──────────────────────────────── timer ────────────────────────────────

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
}

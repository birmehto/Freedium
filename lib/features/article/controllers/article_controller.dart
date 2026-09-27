import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
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
import '../../../core/storage/app_database.dart';
import '../../../core/utils/app_log.dart';
import '../../favorites/models/favorite_article.dart';
import '../../settings/models/reader_settings.dart';
import '../models/article_meta.dart';
import '../models/article_request.dart';
import '../models/reading_progress.dart';

/// Owns the state of one open article: the loaded URL, extracted metadata,
/// reader typography, favorite status, reading progress and the offline copy.
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

  /// True while the article on screen came from the on-device cache rather than
  /// from a mirror, so the reader can say so instead of quietly serving stale
  /// content.
  final isOffline = false.obs;

  /// Whether a saved copy of this article exists.
  final hasOfflineCopy = false.obs;

  /// True while the article's local copy is being written or dropped, so a
  /// second press cannot race the first.
  final isStoringArticle = false.obs;

  /// How far through the article the reader is, in `0..1`.
  final readingProgress = 0.0.obs;

  InAppWebViewController? webViewController;

  Timer? _loadingTimer;

  /// Coalesces the flood of scroll callbacks into one store write.
  Timer? _scrollTimer;

  final List<Worker> _workers = [];

  /// Mirrors tried for the current article, newest first. Backs the reader's
  /// "switch source" affordance, so it holds source ids rather than the URLs
  /// they were asked for.
  final RxList<String> attemptedMirrors = <String>[].obs;

  /// Where the reader left off last time, and the load that fetches it.
  ReadingProgress? _savedProgress;
  Future<void>? _progressLoad;

  /// Metadata read out of the loaded document, kept so a save pressed later
  /// does not have to extract it again.
  ArticleMeta? _meta;

  /// True once the stored position has been applied to the loaded document.
  bool _scrollRestored = false;

  /// Whether the failure of the current navigation has already been handled, so
  /// a second error callback for the same request cannot start a second
  /// failover. Reset when the next navigation starts.
  bool _errorHandled = false;

  /// The last position written to the store, so a settled reader does not
  /// rewrite the same value on every scroll event.
  ReadingProgress? _persistedProgress;

  // ────────────────────────────── derived ────────────────────────────────

  bool get isDarkMode => _theme.isDarkMode.value;

  double get fontSize => readingSettings.value.fontSize;

  /// Derived from the library store, so there is only one favorites state.
  bool get isFavorite => _storage.library.isFavorite(originalUrl.value);

  String get articleDomain => ArticleUrl.hostOf(originalUrl.value) ?? '';

  /// Percentage of the article read, for the progress affordances.
  int get readingProgressPercent => (readingProgress.value * 100).round();

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
    _progressLoad = _loadSavedProgress(url);
    unawaited(_checkOfflineCopy(url));

    _setupReactions();
  }

  @override
  void onClose() {
    _loadingTimer?.cancel();
    _scrollTimer?.cancel();

    // A debounced settings write is still pending when the reader is closed, so
    // the last change is written here rather than lost with the worker.
    final stored = _storage.preferences.readerSettings;
    if (stored.fontSize != readingSettings.value.fontSize ||
        stored.themeMode != readingSettings.value.themeMode ||
        stored.fontFamily != readingSettings.value.fontFamily) {
      _storage.preferences.readerSettings = readingSettings.value;
    }

    // The last scroll position is written here rather than left to the debounce
    // timer, which would never fire for a reader who closes the article while
    // still scrolling. GetX marks a controller closed *before* calling
    // `onClose`, so this is the one path allowed to write after that point.
    unawaited(_persistProgress(afterClose: true));

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

    // The document is restyled immediately, so the reader sees the change as
    // they make it. Only the write is debounced: dragging the font-size slider
    // otherwise queues a JSON encode and a database write per pointer tick.
    _workers.add(ever(readingSettings, (settings) => injectCustomCSS()));
    _workers.add(
      debounce(
        readingSettings,
        (settings) => _storage.preferences.readerSettings = settings,
        time: const Duration(milliseconds: 300),
      ),
    );
  }

  void _startLoading(String url) {
    final resolved = _resolver.resolve(url);
    if (resolved != null) {
      final sourceId = _resolver.lastSourceId;
      if (sourceId != null) attemptedMirrors.add(sourceId);
    }

    currentUrl.value = resolved ?? url;
    _startLoadingTimer();
  }

  // ────────────────────────────── WebView ────────────────────────────────

  /// A new navigation has begun.
  ///
  /// Arms the watchdog again: a mirror that redirects, or a second navigation
  /// started by the page itself, would otherwise leave the reader loading
  /// forever, because the previous load already cancelled the timer.
  void onPageStart(String? url) {
    errorMessage.value = '';
    isLoading.value = true;

    // A new load starts from empty: leaving the previous run's 100% in place
    // shows a full progress bar for the whole of the next load.
    loadingProgress.value = 0;

    // One error is reported per navigation. Both an HTTP error and a transport
    // error can arrive for the same request, and the second one would retire a
    // mirror that never served the article.
    _errorHandled = false;

    _startLoadingTimer();
    if (url != null) currentUrl.value = url;
    appLog('ArticleController.onPageStart: isLoading=true, url=$url');
  }

  /// The new document is painted and visible to the reader.
  ///
  /// The loader is dismissed here rather than waiting for `onLoadStop`, which
  /// some backends never send at all: the article is on screen, so there is
  /// nothing left to wait for.
  void onPageCommitVisible() {
    appLog(
      'ArticleController.onPageCommitVisible: isLoading=${isLoading.value}, isInitialLoad=${isInitialLoad.value}',
    );
    if (isLoading.value || isInitialLoad.value) _stopLoading();
  }

  void setWebViewController(InAppWebViewController controller) {
    webViewController = controller;
  }

  void onPageLoaded() {
    appLog('ArticleController.onPageLoaded: calling _stopLoading');
    _stopLoading();

    // A saved copy and a WebView error page both finish loading too, and
    // crediting a mirror for either would reset the failure count of the mirror
    // that just failed — which is the one thing the health model is for.
    if (!isOffline.value) {
      final sourceId = _resolver.lastSourceId;
      _resolver.reportSuccess(sourceId);
    }

    unawaited(_onContentReady());
  }

  Future<void> onPageError(String message) async {
    // Both an HTTP error and a transport error can fire for the same request.
    if (_errorHandled) return;
    _errorHandled = true;

    _stopLoading();

    final failedSourceId = _resolver.lastSourceId;
    _resolver.reportFailure(failedSourceId);

    // Try the next mirror before surfacing the failure: a single dead backend
    // should not end the reading session. Mirrors already tried for this
    // article are excluded, so the reader walks the catalog instead of bouncing
    // between the first two.
    final fallback = _resolver.nextFallback(
      attempted: attemptedMirrors.toSet(),
    );
    if (fallback != null) {
      final sourceId = _resolver.lastSourceId;
      if (sourceId != null) attemptedMirrors.add(sourceId);

      errorMessage.value = '';
      isLoading.value = true;
      loadingProgress.value = 0;
      _startLoadingTimer();
      await _loadUrl(fallback);
      return;
    }

    // Every mirror is exhausted. A saved copy beats an error page, so the cache
    // is consulted before the failure is shown.
    final copy = await _offlineCopy();
    if (isClosed) return;

    if (copy != null) {
      await _showOfflineCopy(copy);
      return;
    }

    errorMessage.value = message;
    loadingProgress.value = 0;
    isLoading.value = false;
    isInitialLoad.value = false;
  }

  /// Reports WebView load progress as a 0..1 fraction.
  ///
  /// The load is finished at 100%, so the loading indicators are dismissed there
  /// and then: waiting for `onLoadStop` alone is what left the reader spinning
  /// on an article that had already finished loading.
  void updateProgress(double progress) {
    final value = (progress / 100).clamp(0.0, 1.0).toDouble();
    loadingProgress.value = value;
    appLog(
      'ArticleController.updateProgress: value=$value, isLoading=${isLoading.value}',
    );
    if (value >= 1.0) _stopLoading();
  }

  Future<void> requestRefresh() async {
    errorMessage.value = '';
    isLoading.value = true;
    loadingProgress.value = 0;
    _startLoadingTimer();

    final controller = webViewController;

    // Refreshing an offline copy is a request to go back online, not a reload
    // of the copy that is already on screen. Offline mode is only left once a
    // mirror is actually available, so a refresh with no network leaves the
    // banner and the saved copy alone instead of claiming to be online.
    if (isOffline.value) {
      final resolved = _resolver.resolve(originalUrl.value);
      if (resolved == null) {
        isLoading.value = false;
        return;
      }

      isOffline.value = false;
      await _loadUrl(resolved);
      return;
    }

    // Nothing to refresh into: without a WebView the watchdog would run to its
    // timeout and replace a working article with an error.
    if (controller == null) {
      isLoading.value = false;
      return;
    }

    await controller.reload();
  }

  /// Handles the HTTP status codes a mirror can answer with.
  Future<void> handleServerError(int statusCode) {
    return onPageError(switch (statusCode) {
      502 => 'Bad Gateway (502). Server unavailable.',
      503 => 'Service Unavailable (503).',
      _ => 'Server error ($statusCode)',
    });
  }

  Future<void> switchToMirror(String mirrorId) async {
    _resolver.setPreferred(mirrorId);
    final original = ArticleUrl.canonicalize(originalUrl.value);
    if (original.isEmpty) return;

    final newUrl = _resolver.resolve(original);
    if (newUrl == null || newUrl == currentUrl.value) return;

    isOffline.value = false;
    isLoading.value = true;
    loadingProgress.value = 0;
    _startLoadingTimer();

    await _loadUrl(newUrl);
  }

  Future<void> _loadUrl(String url) async {
    if (webViewController == null) {
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

  /// Everything that happens once a document is fully loaded: its metadata and
  /// the reader's place in it.
  ///
  /// Nothing is written to the offline store here. An article is kept because
  /// the reader favorited it, not because it happened to be read, so simply
  /// opening a story costs no storage.
  Future<void> _onContentReady() async {
    // The saved copy is a bare article fragment: it has no metadata of its own,
    // so extracting it would find nothing and overwrite what the store recorded
    // with empty values.
    if (!isOffline.value) {
      _meta = await _extractMetadata();
    }

    await _restoreScrollPosition();
  }

  /// Reads metadata out of the loaded document and publishes it.
  ///
  /// Returns the extracted metadata, or `null` when the page carried none.
  Future<ArticleMeta?> _extractMetadata() async {
    final controller = webViewController;
    if (isClosed || controller == null) return null;

    try {
      final result = await controller.evaluateJavascript(
        source: ReaderTheme.extractMetaJs,
      );
      if (result is! String || result.isEmpty) return null;
      final meta = ArticleMeta.fromJson(
        jsonDecode(result) as Map<String, dynamic>?,
      );
      if (meta.title.isEmpty) return null;
      articleTitle.value = meta.title;
      articleAuthor.value = meta.author ?? '';
      articlePublication.value = meta.publication ?? '';
      wordCount.value = meta.wordCount;
      readingTime.value = meta.readingTimeMinutes;
      publishedAt.value = meta.publishedAt;
      await _storage.library.cacheMeta(originalUrl.value, meta);
      return meta;
    } catch (error) {
      appLog(
        'Could not extract metadata: $error',
        name: 'Reader',
        level: LogLevel.warning,
      );
      return null;
    }
  }

  // ─────────────────────────────── offline ───────────────────────────────

  /// Writes the loaded article to the offline store, reporting whether it stuck.
  ///
  /// The store keeps the article on its own, not the page around it, so the body
  /// has to be read back out of the document the reader is looking at.
  Future<bool> _saveArticleOffline() async {
    final url = originalUrl.value;
    if (url.isEmpty) return false;

    final html = await readArticleHtml();
    if (html == null) return false;

    return _storage.cache.saveWithMeta(
      url: url,
      html: html,
      // A save can happen before the metadata has been read, so what the reader
      // already has on screen stands in rather than losing the title.
      meta: _meta ?? _metaFromReaderState(),
      domain: articleDomain.isEmpty ? null : articleDomain,
      // A favorite is the reader's own decision to keep something for good, so
      // it survives eviction even when the store is full.
      keep: [for (final item in _storage.library.favorites) item.url],
    );
  }

  /// The loaded article's own markup, or `null` when there is no document to
  /// read it from.
  ///
  /// The WebView is the only place the body exists, so this is the seam a test
  /// replaces: an article that is not on screen cannot be stored.
  @visibleForTesting
  Future<String?> readArticleHtml() async {
    final controller = webViewController;
    if (isClosed || controller == null) return null;

    try {
      final result = await controller.evaluateJavascript(
        source: ReaderTheme.extractArticleHtmlJs,
      );
      if (result is! String || result.isEmpty) return null;

      final payload = jsonDecode(result);
      if (payload is! Map<String, dynamic>) return null;
      if (payload['found'] != true) return null;

      final html = payload['html'];
      if (html is! String || html.trim().isEmpty) return null;

      return html;
    } catch (error) {
      appLog(
        'Could not read the article to save it: $error',
        name: 'Reader',
        level: LogLevel.warning,
      );
      return null;
    }
  }

  /// Metadata assembled from what is already on screen.
  ArticleMeta _metaFromReaderState() => ArticleMeta(
    title: articleTitle.value,
    author: articleAuthor.value.isEmpty ? null : articleAuthor.value,
    publication: articlePublication.value.isEmpty
        ? null
        : articlePublication.value,
    publishedAt: publishedAt.value,
    wordCount: wordCount.value,
  );

  /// The saved copy of the current article, or `null`.
  Future<CachedArticle?> _offlineCopy() async {
    try {
      return await _storage.cache.read(originalUrl.value);
    } catch (error) {
      appLog(
        'Could not read cached article: $error',
        name: 'Reader',
        level: LogLevel.warning,
      );
      return null;
    }
  }

  /// Replaces the failed page with the saved copy.
  Future<void> _showOfflineCopy(CachedArticle copy) async {
    final controller = webViewController;

    errorMessage.value = '';
    isOffline.value = true;
    hasOfflineCopy.value = true;
    readingProgress.value = _savedProgress?.ratio ?? 0;

    // The metadata came from a page that never loaded, so whatever the cache
    // recorded is all there is. It is better than the title guessed from the
    // URL, so it wins outright.
    if (copy.title.isNotEmpty) articleTitle.value = copy.title;
    if (articleAuthor.value.isEmpty && copy.author != null) {
      articleAuthor.value = copy.author!;
    }
    if (articlePublication.value.isEmpty && copy.publication != null) {
      articlePublication.value = copy.publication!;
    }
    if (wordCount.value == 0) {
      wordCount.value = copy.wordCount;
      readingTime.value = (copy.wordCount / ArticleMeta.kWordsPerMinute).ceil();
    }

    if (controller == null) return;

    _stopLoading();
    try {
      // `baseUrl` lets the article's relative image paths resolve the same way
      // they did on the page they came from.
      await controller.loadData(
        data: _offlineDocument(copy),
        baseUrl: WebUri(copy.url),
      );
    } catch (error) {
      appLog(
        'Could not open cached article: $error',
        name: 'Reader',
        level: LogLevel.error,
      );
      errorMessage.value = 'Could not open the saved copy of this article.';
    }
  }

  /// Wraps a cached body in the document the reader expects.
  ///
  /// The stored markup is the article element alone, so it needs a document
  /// around it, a title for the app bar to fall back to, and the viewport meta
  /// that keeps text sized in CSS pixels rather than scaled to the device.
  String _offlineDocument(CachedArticle copy) {
    final title = _escapeHtml(
      copy.title.isNotEmpty ? copy.title : 'Saved article',
    );

    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$title</title>
</head>
<body>
<article>
${copy.html}
</article>
</body>
</html>
''';
  }

  static String _escapeHtml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  // ──────────────────────────── reading progress ─────────────────────────

  Future<void> _loadSavedProgress(String url) async {
    try {
      _savedProgress = await _storage.progress.progressFor(url);
      if (_savedProgress != null) {
        readingProgress.value = _savedProgress!.ratio;
      }
    } catch (error) {
      appLog(
        'Could not read reading progress: $error',
        name: 'Progress',
        level: LogLevel.warning,
      );
    }
  }

  Future<void> _checkOfflineCopy(String url) async {
    try {
      hasOfflineCopy.value = await _storage.cache.contains(url);
    } catch (error) {
      appLog(
        'Could not check for a saved copy: $error',
        name: 'Reader',
        level: LogLevel.warning,
      );
    }
  }

  /// Called from the WebView's scroll callback, which fires far more often than
  /// anything useful can be done with the value.
  void reportScroll() {
    if (isClosed) return;

    _scrollTimer?.cancel();
    _scrollTimer = Timer(
      AppConstants.scrollSettleDelay,
      () => unawaited(_persistProgress()),
    );
  }

  /// Measures the document and stores the position, if it moved.
  ///
  /// [afterClose] exists only for the final flush in `onClose`, which runs once
  /// the controller is already flagged closed.
  Future<void> _persistProgress({bool afterClose = false}) async {
    final controller = webViewController;
    if (controller == null) return;
    if (!afterClose && isClosed) return;

    final url = originalUrl.value;
    if (url.isEmpty) return;

    try {
      final result = await controller.evaluateJavascript(
        source: ReaderTheme.scrollMetricsJs,
      );
      if (result is! String || result.isEmpty) return;

      final payload = jsonDecode(result);
      if (payload is! Map<String, dynamic>) return;

      final ratio = (payload['ratio'] as num?)?.toDouble() ?? 0;
      final offset = (payload['y'] as num?)?.toDouble() ?? 0;

      _storeProgress(url, ratio, offset);
    } catch (error) {
      // A document that cannot be measured is not worth an error report: the
      // reader is still perfectly readable, it just will not resume.
      appLog(
        'Could not measure reading progress: $error',
        name: 'Progress',
        level: LogLevel.warning,
      );
    }
  }

  /// Records [ratio] unless it is unstarted, unchanged, or already stored.
  void _storeProgress(String url, double ratio, double offset) {
    final position = ratio.clamp(0.0, 1.0);

    if (position <= ReadingProgress.kStartedThreshold) return;

    final last = _persistedProgress;
    if (last != null && (last.ratio - position).abs() < 0.01) return;

    readingProgress.value = position;
    _persistedProgress = ReadingProgress(
      url: url,
      ratio: position,
      offset: offset,
      updatedAt: DateTime.now(),
    );

    unawaited(_storage.progress.save(url, ratio: position, offset: offset));
  }

  /// Puts the reader back where they left off, once per loaded document.
  Future<void> _restoreScrollPosition() async {
    if (_scrollRestored) return;

    // The stored position may still be in flight when the page finishes
    // loading, so it is awaited rather than read.
    await _progressLoad;
    if (isClosed) return;

    final progress = _savedProgress;
    if (progress == null || !progress.isStarted) return;

    _scrollRestored = true;

    final controller = webViewController;
    if (controller == null) return;

    try {
      await controller.evaluateJavascript(
        source: ReaderTheme.restoreScrollScript(
          offset: progress.offset,
          ratio: progress.ratio,
        ),
      );
    } catch (error) {
      appLog(
        'Could not restore reading position: $error',
        name: 'Progress',
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

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error) {
      // No browser installed, or the platform refused the launch: without this
      // the tap does nothing at all and the reason is invisible.
      final exception = AppException.from(error, context: 'openInBrowser');
      appLog(exception.toString(), name: 'Reader', level: LogLevel.warning);
      showMessage('No app available to open this link');
    }
  }

  Future<void> copyLink() => _clipboard.copyToClipboard(originalUrl.value);

  Future<void> shareArticle() async {
    final url = originalUrl.value;
    if (url.isEmpty) return;

    try {
      await SharePlus.instance.share(
        ShareParams(
          title: 'Share from Freedium',
          text: '${articleTitle.value}\n\n$url',
        ),
      );
    } catch (error) {
      // Sharing throws when the device has nothing that can receive the text.
      final exception = AppException.from(error, context: 'shareArticle');
      appLog(exception.toString(), name: 'Reader', level: LogLevel.warning);
      showMessage('Could not share this article');
    }
  }

  /// Favourites an article, or removes it.
  ///
  /// A favorite is also kept on the device so it can be read without a network,
  /// and taking the favorite away takes the copy with it — one decision, one
  /// stored article, nothing left behind in Settings to clean up.
  ///
  /// The favorite itself is recorded first, so the heart responds straight away
  /// and a body that cannot be read does not cost the reader their save.
  Future<void> toggleFavorite() async {
    final url = originalUrl.value;
    if (url.isEmpty) return;
    if (isStoringArticle.value) return;

    final article = FavoriteArticle(
      title: articleTitle.value,
      url: url,
      visitedAt: DateTime.now(),
      author: articleAuthor.value.isEmpty ? null : articleAuthor.value,
      domain: articleDomain.isEmpty ? null : articleDomain,
    );

    // Claimed before the first await, and the direction read before the write:
    // two quick taps would otherwise both see the article as un-favorited, and
    // the second would undo the first.
    final favorited = !isFavorite;
    isStoringArticle.value = true;

    try {
      await _storage.library.toggleFavorite(article);

      if (favorited) {
        hasOfflineCopy.value = await _saveArticleOffline();
      } else {
        await _storage.cache.remove(url);
        hasOfflineCopy.value = false;
      }
    } finally {
      isStoringArticle.value = false;
    }
  }

  /// Test-only hook: exposes [_titleFromUrl].
  @visibleForTesting
  void debugTitleFromUrl(String url) {
    articleTitle.value = _titleFromUrl(url);
  }

  String _titleFromUrl(String url) {
    final segments = Uri.tryParse(url)?.pathSegments;
    if (segments == null) return 'Article';

    // A trailing slash leaves an empty final segment, and an empty title in the
    // app bar is also what gets saved into the library.
    final slug = segments.lastWhere(
      (segment) => segment.isNotEmpty,
      orElse: () => '',
    );
    if (slug.isEmpty) return 'Article';

    return slug
        .replaceAll('-', ' ')
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .join(' ');
  }

  /// Shows a short message to the reader, e.g. when a share has nowhere to go.
  void showMessage(String message) {
    if (Get.context case final context?) {
      M3ESnackbar.show(context, message: message);
    }
  }

  // ──────────────────────────────── timer ────────────────────────────────

  void _startLoadingTimer() {
    _loadingTimer?.cancel();

    _loadingTimer = Timer(AppConstants.webViewTimeout, () {
      if (isLoading.value) {
        unawaited(
          onPageError(
            'Loading timeout. Please check your connection and try again.',
          ),
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
    appLog('ArticleController._stopLoading: isLoading=${isLoading.value}');
  }
}

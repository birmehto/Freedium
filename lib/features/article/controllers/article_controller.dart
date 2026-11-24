import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/reader_theme.dart';
import '../../../core/controllers/app_controllers.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/article_url.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/utils/app_log.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../favorites/models/favorite_article.dart';
import '../../settings/models/reader_settings.dart';
import '../models/article_meta.dart';
import '../models/article_request.dart';

/// Everything the reader screen displays about one article.
class ArticleState {
  const ArticleState({
    this.currentUrl = '',
    this.originalUrl = '',
    this.errorMessage = '',
    this.isLoading = true,
    this.isInitialLoad = true,
    this.loadingProgress = 0,
    this.articleTitle = '',
    this.articleAuthor = '',
    this.articlePublication = '',
    this.publishedAt,
    this.wordCount = 0,
    this.readingTime = 0,
    this.isOffline = false,
    this.hasOfflineCopy = false,
    this.isStoringArticle = false,
    this.isFavorite = false,
    this.attemptedMirrors = const [],
  });

  final String currentUrl;
  final String originalUrl;
  final String errorMessage;
  final bool isLoading;
  final bool isInitialLoad;
  final double loadingProgress;
  final String articleTitle;
  final String articleAuthor;
  final String articlePublication;
  final DateTime? publishedAt;
  final int wordCount;
  final int readingTime;
  final bool isOffline;
  final bool hasOfflineCopy;
  final bool isStoringArticle;
  final bool isFavorite;
  final List<String> attemptedMirrors;

  ArticleState copyWith({
    String? currentUrl,
    String? originalUrl,
    String? errorMessage,
    bool? isLoading,
    bool? isInitialLoad,
    double? loadingProgress,
    String? articleTitle,
    String? articleAuthor,
    String? articlePublication,
    DateTime? publishedAt,
    bool clearPublishedAt = false,
    int? wordCount,
    int? readingTime,
    bool? isOffline,
    bool? hasOfflineCopy,
    bool? isStoringArticle,
    bool? isFavorite,
    List<String>? attemptedMirrors,
  }) {
    return ArticleState(
      currentUrl: currentUrl ?? this.currentUrl,
      originalUrl: originalUrl ?? this.originalUrl,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
      isInitialLoad: isInitialLoad ?? this.isInitialLoad,
      loadingProgress: loadingProgress ?? this.loadingProgress,
      articleTitle: articleTitle ?? this.articleTitle,
      articleAuthor: articleAuthor ?? this.articleAuthor,
      articlePublication: articlePublication ?? this.articlePublication,
      publishedAt: clearPublishedAt ? null : publishedAt ?? this.publishedAt,
      wordCount: wordCount ?? this.wordCount,
      readingTime: readingTime ?? this.readingTime,
      isOffline: isOffline ?? this.isOffline,
      hasOfflineCopy: hasOfflineCopy ?? this.hasOfflineCopy,
      isStoringArticle: isStoringArticle ?? this.isStoringArticle,
      isFavorite: isFavorite ?? this.isFavorite,
      attemptedMirrors: attemptedMirrors ?? this.attemptedMirrors,
    );
  }
}

final articleControllerProvider =
    NotifierProvider<ArticleController, ArticleState>(ArticleController.new);

/// Owns the state of one open article. The screen calls [open] with the request
/// when it is created; typography and favorites are shared providers, not
/// duplicated here.
class ArticleController extends Notifier<ArticleState> {
  WebViewController? webViewController;

  Timer? _loadingTimer;
  ArticleMeta? _meta;
  bool _errorHandled = false;
  bool _disposed = false;

  @override
  ArticleState build() {
    // Captured during build: calling ref.read inside onDispose is disallowed by
    // Riverpod once the container is being torn down.
    final readerSettingsNotifier = ref.read(readerSettingsProvider.notifier);

    ref.listen(themeControllerProvider, (_, _) => injectCustomCSS());
    ref.listen(readerSettingsProvider, (_, _) => injectCustomCSS());
    ref.listen(libraryControllerProvider, (previous, next) {
      if (previous == null) return;
      final url = state.originalUrl;
      state = state.copyWith(
        isFavorite: next.any((article) => article.url.trim() == url.trim()),
      );
    });

    ref.onDispose(() {
      _disposed = true;
      _loadingTimer?.cancel();
      readerSettingsNotifier.flush();
    });

    return const ArticleState();
  }

  ReaderSettings get readerSettings => ref.read(readerSettingsProvider);
  bool get isDarkMode => ref.read(themeControllerProvider).isDarkMode;
  double get fontSize => readerSettings.fontSize;

  String get articleDomain => ArticleUrl.hostOf(state.originalUrl) ?? '';

  /// Hosts the reader may navigate to: every configured mirror, their redirect
  /// aliases, and the one currently loaded. Anything else is handed to the
  /// browser.
  Set<String> get allowedNavigationHosts => {
    for (final source in ref.read(articleResolverProvider).sources)
      ...source.allowedHosts,
    if (Uri.tryParse(state.currentUrl)?.host case final host?)
      host.toLowerCase(),
  };

  /// Starts loading the article described by [request].
  Future<void> open(ArticleRequest request) async {
    if (!request.isValid) {
      state = state.copyWith(
        errorMessage: AppException.invalidUrl().userMessage,
        isLoading: false,
        isInitialLoad: false,
      );
      return;
    }

    final url = request.sourceUrl;
    final favorite = ref
        .read(libraryControllerProvider)
        .any((article) => article.url.trim() == url.trim());

    // The provider is app-scoped, so opening a second article must not inherit
    // the previous article's metadata, error or offline state.
    _errorHandled = false;
    _meta = null;
    webViewController = null;
    _loadingTimer?.cancel();
    state = ArticleState(originalUrl: url, isFavorite: favorite);

    _loadPreferences(url);
    _startLoading(request.url);
    unawaited(_checkOfflineCopy(url));
  }

  void _loadPreferences(String url) {
    final preferences = ref.read(storageServiceProvider).preferences;
    final resolver = ref.read(articleResolverProvider);

    resolver.setPreferred(preferences.preferredMirror);
    resolver.autoFallback = preferences.autoFallback;

    final cached = ref.read(storageServiceProvider).library.metaFor(url);
    if (cached == null) {
      state = state.copyWith(articleTitle: _titleFromUrl(url));
      return;
    }

    state = state.copyWith(
      articleTitle: cached.title,
      articleAuthor: cached.author ?? '',
      articlePublication: cached.publication ?? '',
      wordCount: cached.wordCount,
      readingTime: cached.readingTimeMinutes,
      publishedAt: cached.publishedAt,
    );
  }

  void _startLoading(String url) {
    final resolver = ref.read(articleResolverProvider);
    final resolved = resolver.resolve(url);
    if (resolved != null && resolver.lastSourceId != null) {
      state = state.copyWith(
        attemptedMirrors: [...state.attemptedMirrors, resolver.lastSourceId!],
      );
    }
    state = state.copyWith(currentUrl: resolved ?? url);
    _startLoadingTimer();
  }

  //  WebView ─

  void onPageStart(String? url) {
    state = state.copyWith(
      errorMessage: '',
      isLoading: true,
      loadingProgress: 0,
    );
    // Both an HTTP error and a transport error can arrive for one request;
    // handle only the first so a dead mirror is retired once.
    _errorHandled = false;
    _startLoadingTimer();
    if (url != null) state = state.copyWith(currentUrl: url);
  }

  void onPageCommitVisible() {
    if (state.isLoading || state.isInitialLoad) _stopLoading();
  }

  void setWebViewController(WebViewController controller) {
    webViewController = controller;
    injectCustomCSS();
  }

  void onPageLoaded() {
    _stopLoading();

    // An offline copy or an error page also finishes loading; crediting a mirror
    // for either would reset the failure count of the mirror that just failed.
    if (!state.isOffline) {
      ref.read(articleResolverProvider).reportSuccess();
    }
    unawaited(_onContentReady());
  }

  Future<void> onPageError(String message) async {
    if (_errorHandled || _disposed) return;
    _errorHandled = true;
    _stopLoading();

    final resolver = ref.read(articleResolverProvider);
    resolver.reportFailure();

    // Try the next mirror before showing a failure. Already tried mirrors are
    // excluded so the reader walks the catalog instead of bouncing between two.
    final fallback = resolver.nextFallback(
      attempted: state.attemptedMirrors.toSet(),
    );
    if (fallback != null) {
      if (resolver.lastSourceId != null) {
        state = state.copyWith(
          attemptedMirrors: [...state.attemptedMirrors, resolver.lastSourceId!],
        );
      }
      state = state.copyWith(
        errorMessage: '',
        isLoading: true,
        loadingProgress: 0,
      );
      _startLoadingTimer();
      await _loadUrl(fallback);
      return;
    }

    // Every mirror is exhausted: a saved copy beats an error page.
    final copy = await _offlineCopy();
    if (_disposed) return;

    if (copy != null) {
      await _showOfflineCopy(copy);
      return;
    }

    state = state.copyWith(
      errorMessage: message,
      loadingProgress: 0,
      isLoading: false,
      isInitialLoad: false,
    );
  }

  void updateProgress(double progress) {
    final value = (progress / 100).clamp(0.0, 1.0).toDouble();
    state = state.copyWith(loadingProgress: value);
    if (value >= 1.0) _stopLoading();
  }

  Future<void> requestRefresh() async {
    state = state.copyWith(
      errorMessage: '',
      isLoading: true,
      loadingProgress: 0,
    );
    _startLoadingTimer();

    final controller = webViewController;

    // Refreshing an offline copy means "go back online", not "reload the copy".
    if (state.isOffline) {
      final resolved = ref
          .read(articleResolverProvider)
          .resolve(state.originalUrl);
      if (resolved == null) {
        state = state.copyWith(isLoading: false);
        return;
      }
      state = state.copyWith(isOffline: false);
      await _loadUrl(resolved);
      return;
    }

    // Without a WebView the watchdog would replace a working article with an
    // error when its timer fires.
    if (controller == null) {
      state = state.copyWith(isLoading: false);
      return;
    }
    await controller.reload();
  }

  Future<void> handleServerError(int statusCode) {
    return onPageError(switch (statusCode) {
      502 => 'Bad Gateway (502). Server unavailable.',
      503 => 'Service Unavailable (503).',
      _ => 'Server error ($statusCode)',
    });
  }

  Future<void> _loadUrl(String url) async {
    final controller = webViewController;
    if (controller == null) {
      state = state.copyWith(currentUrl: url);
      return;
    }
    await controller.loadRequest(Uri.parse(url));
  }

  //  reader ─

  void updateReaderSettings(ReaderSettings settings) =>
      ref.read(readerSettingsProvider.notifier).update(settings);

  void setFontSize(double size) =>
      ref.read(readerSettingsProvider.notifier).setFontSize(size);

  /// Re-applies typography and color to the loaded document.
  Future<void> injectCustomCSS() async {
    final controller = webViewController;
    if (_disposed || controller == null) return;

    final preview = ReaderTheme.previewColors(
      readerSettings,
      systemDark: isDarkMode,
    );
    unawaited(
      controller.setBackgroundColor(ReaderTheme.hexToColor(preview.background)),
    );

    final css = ReaderTheme.getCss(
      settings: readerSettings,
      systemDark: isDarkMode,
    );
    try {
      await controller.runJavaScript(ReaderTheme.injectCssScript(css));
    } catch (error) {
      appLog(
        'Could not inject CSS: $error',
        name: 'Reader',
        level: LogLevel.warning,
      );
    }
  }

  //  metadata ──────────────────────────────

  /// Extracts metadata once a document is visible. Nothing is written to the
  /// offline store here: an article is kept because it was favorited, not
  /// because it happened to be read.
  Future<void> _onContentReady() async {
    if (!state.isOffline) _meta = await _extractMetadata();
  }

  Future<ArticleMeta?> _extractMetadata() async {
    final controller = webViewController;
    if (_disposed || controller == null) return null;

    try {
      final result = await _readJsString(controller, ReaderTheme.extractMetaJs);
      if (result == null || result.isEmpty) return null;

      final meta = ArticleMeta.fromJson(
        jsonDecode(result) as Map<String, dynamic>?,
      );
      if (meta.title.isEmpty) return null;

      state = state.copyWith(
        articleTitle: meta.title,
        articleAuthor: meta.author ?? '',
        articlePublication: meta.publication ?? '',
        wordCount: meta.wordCount,
        readingTime: meta.readingTimeMinutes,
        publishedAt: meta.publishedAt,
      );
      await ref
          .read(storageServiceProvider)
          .library
          .cacheMeta(state.originalUrl, meta);
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

  //  offline

  Future<bool> _saveArticleOffline() async {
    final url = state.originalUrl;
    if (url.isEmpty) return false;

    final html = await readArticleHtml();
    if (html == null) return false;

    return ref
        .read(storageServiceProvider)
        .cache
        .saveWithMeta(
          url: url,
          html: html,
          // A save can precede metadata extraction; use what is on screen.
          meta: _meta ?? _metaFromReaderState(),
          domain: articleDomain.isEmpty ? null : articleDomain,
          keep: [
            for (final item in ref.read(libraryControllerProvider)) item.url,
          ],
        );
  }

  @visibleForTesting
  Future<String?> readArticleHtml() async {
    final controller = webViewController;
    if (_disposed || controller == null) return null;

    try {
      final result = await _readJsString(
        controller,
        ReaderTheme.extractArticleHtmlJs,
      );
      if (result == null || result.isEmpty) return null;

      final payload = jsonDecode(result);
      if (payload is! Map<String, dynamic>) return null;
      if (payload['found'] != true) return null;

      final html = payload['html'];
      if (html is! String || html.trim().isEmpty) return null;
      return html;
    } catch (error) {
      appLog(
        'Could not read article to save it: $error',
        name: 'Reader',
        level: LogLevel.warning,
      );
      return null;
    }
  }

  ArticleMeta _metaFromReaderState() => ArticleMeta(
    title: state.articleTitle,
    author: state.articleAuthor.isEmpty ? null : state.articleAuthor,
    publication: state.articlePublication.isEmpty
        ? null
        : state.articlePublication,
    publishedAt: state.publishedAt,
    wordCount: state.wordCount,
  );

  Future<CachedArticle?> _offlineCopy() async {
    try {
      return await ref
          .read(storageServiceProvider)
          .cache
          .read(state.originalUrl);
    } catch (error) {
      appLog(
        'Could not read cached article: $error',
        name: 'Reader',
        level: LogLevel.warning,
      );
      return null;
    }
  }

  Future<void> _showOfflineCopy(CachedArticle copy) async {
    final controller = webViewController;

    state = state.copyWith(
      errorMessage: '',
      isOffline: true,
      hasOfflineCopy: true,
    );

    // Metadata from the cache wins over the title guessed from the URL.
    state = state.copyWith(
      articleTitle: copy.title.isNotEmpty ? copy.title : state.articleTitle,
      articleAuthor: state.articleAuthor.isEmpty && copy.author != null
          ? copy.author
          : state.articleAuthor,
      articlePublication:
          state.articlePublication.isEmpty && copy.publication != null
          ? copy.publication
          : state.articlePublication,
      wordCount: state.wordCount == 0 ? copy.wordCount : state.wordCount,
      readingTime: state.wordCount == 0
          ? (copy.wordCount / ArticleMeta.kWordsPerMinute).ceil()
          : state.readingTime,
    );

    if (controller == null) return;

    _stopLoading();
    try {
      // baseUrl keeps relative image paths resolving as they did originally.
      await controller.loadHtmlString(
        _offlineDocument(copy),
        baseUrl: copy.url,
      );
    } catch (error) {
      appLog(
        'Could not open cached article: $error',
        name: 'Reader',
        level: LogLevel.error,
      );
      state = state.copyWith(
        errorMessage: 'Could not open the saved copy of this article.',
      );
    }
  }

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

  Future<void> _checkOfflineCopy(String url) async {
    try {
      final exists = await ref.read(storageServiceProvider).cache.contains(url);
      if (!_disposed) state = state.copyWith(hasOfflineCopy: exists);
    } catch (error) {
      appLog(
        'Could not check for a saved copy: $error',
        name: 'Reader',
        level: LogLevel.warning,
      );
    }
  }

  /// Android returns JavaScript strings JSON-encoded, WebKit returns them raw.
  Future<String?> _readJsString(
    WebViewController controller,
    String script,
  ) async {
    final result = await controller.runJavaScriptReturningResult(script);
    if (result is! String) return result.toString();

    if (result.length >= 2 && result.startsWith('"') && result.endsWith('"')) {
      try {
        final decoded = jsonDecode(result);
        if (decoded is String) return decoded;
      } on FormatException {
        // Not JSON after all; the raw string is the best available.
      }
    }
    return result;
  }

  //  actions ──────────────────────────────

  Future<void> openInBrowser() async {
    final uri = Uri.tryParse(state.originalUrl);
    if (uri == null || state.originalUrl.isEmpty) {
      state = state.copyWith(
        errorMessage: AppException.invalidUrl().userMessage,
      );
      return;
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error) {
      final exception = AppException.from(error, context: 'openInBrowser');
      appLog(exception.toString(), name: 'Reader', level: LogLevel.warning);
      AppSnackbar.message('No app available to open this link');
    }
  }

  Future<void> shareArticle() async {
    final url = state.originalUrl;
    if (url.isEmpty) return;
    try {
      await SharePlus.instance.share(
        ShareParams(
          title: 'Share from Freedium',
          text: '${state.articleTitle}\n\n$url',
        ),
      );
    } catch (error) {
      final exception = AppException.from(error, context: 'shareArticle');
      appLog(exception.toString(), name: 'Reader', level: LogLevel.warning);
      AppSnackbar.message('Could not share this article');
    }
  }

  /// Favoriting also saves the article offline; unfavoriting drops the copy.
  Future<void> toggleFavorite() async {
    final url = state.originalUrl;
    if (url.isEmpty || state.isStoringArticle) return;

    final article = FavoriteArticle(
      title: state.articleTitle,
      url: url,
      visitedAt: DateTime.now(),
      author: state.articleAuthor.isEmpty ? null : state.articleAuthor,
      domain: articleDomain.isEmpty ? null : articleDomain,
    );

    // Claim before the first await so two quick taps cannot undo each other.
    final favorited = !state.isFavorite;
    state = state.copyWith(isStoringArticle: true);

    try {
      await ref.read(libraryControllerProvider.notifier).toggle(article);

      if (favorited) {
        final saved = await _saveArticleOffline();
        if (!_disposed) state = state.copyWith(hasOfflineCopy: saved);
        AppSnackbar.message('Article saved to library');
      } else {
        await ref.read(storageServiceProvider).cache.remove(url);
        if (!_disposed) state = state.copyWith(hasOfflineCopy: false);
        AppSnackbar.message('Article removed from library');
      }
    } finally {
      if (!_disposed) state = state.copyWith(isStoringArticle: false);
    }
  }

  @visibleForTesting
  void debugTitleFromUrl(String url) {
    state = state.copyWith(articleTitle: _titleFromUrl(url));
  }

  String _titleFromUrl(String url) {
    final segments = Uri.tryParse(url)?.pathSegments;
    if (segments == null) return 'Article';

    final slug = segments.lastWhere(
      (segment) => segment.isNotEmpty,
      orElse: () => '',
    );
    if (slug.isEmpty) return 'Article';

    return slug
        .replaceAll('-', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  // ─ timer ─

  void _startLoadingTimer() {
    _loadingTimer?.cancel();
    _loadingTimer = Timer(AppConstants.webViewTimeout, () {
      if (state.isLoading) {
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
    state = state.copyWith(
      isLoading: false,
      isInitialLoad: false,
      loadingProgress: 1,
    );
  }
}

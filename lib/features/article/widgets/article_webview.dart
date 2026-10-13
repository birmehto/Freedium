import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/constants/reader_theme.dart';
import '../../../core/utils/app_log.dart';
import '../controllers/article_controller.dart';

/// Hosts the reader itself. Medium's desktop UA is used because the mirror
/// backends serve the paywalled desktop layout.
const String _readerUserAgent =
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

class ArticleWebView extends StatefulWidget {
  const ArticleWebView({
    required this.url,
    required this.controller,
    super.key,
  });

  /// The mirror-proxied URL to load first.
  ///
  /// Read once when the WebView is created. Later navigations are driven by the
  /// controller, so this widget is never rebuilt just because the loaded URL
  /// changed.
  final String url;

  /// The reader's controller, supplied by the route so that the WebView and the
  /// loaders it reports progress to share one instance.
  final ArticleController controller;

  @override
  State<ArticleWebView> createState() => _ArticleWebViewState();
}

class _ArticleWebViewState extends State<ArticleWebView> {
  ArticleController get _controller => widget.controller;

  late final WebViewController _webViewController;

  /// The URL of the document in the main frame.
  ///
  /// `flutter_inappwebview` labelled every error with `isForMainFrame`; the
  /// official plugin does not for HTTP errors on Android, where a 404 image
  /// would otherwise be mistaken for a dead mirror. Tracking the main-frame URL
  /// lets a subresource error be told apart from the document's own.
  String? _mainFrameUrl;

  @override
  void initState() {
    super.initState();
    _webViewController = _createWebViewController();
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _webViewController);
  }

  WebViewController _createWebViewController() {
    final webViewController = WebViewController(
      // Dialogs the page raises are the reader's to dismiss: granting a camera
      // or geolocation request from an article is never wanted.
      onPermissionRequest: (request) => unawaited(request.deny()),
    );

    unawaited(webViewController.setJavaScriptMode(JavaScriptMode.unrestricted));
    unawaited(webViewController.setUserAgent(_readerUserAgent));
    unawaited(webViewController.enableZoom(false));
    // The reader is a scroller, not a bounce-scroller: the stylesheet already
    // declares `overscroll-behavior-y: none`, and the rubber-band effect only
    // fights the article.
    unawaited(webViewController.setOverScrollMode(WebViewOverScrollMode.never));
    unawaited(webViewController.setOnConsoleMessage(_onConsoleMessage));
    unawaited(
      webViewController.setOnJavaScriptAlertDialog(_onJavaScriptAlertDialog),
    );
    unawaited(
      webViewController.setOnJavaScriptConfirmDialog(
        _onJavaScriptConfirmDialog,
      ),
    );
    unawaited(
      webViewController.setOnJavaScriptTextInputDialog(
        _onJavaScriptTextInputDialog,
      ),
    );
    unawaited(
      webViewController.setNavigationDelegate(_buildNavigationDelegate()),
    );

    _controller.setWebViewController(webViewController);

    unawaited(
      webViewController.loadRequest(
        Uri.parse(widget.url),
        headers: const {'Accept-Language': 'en-US,en;q=0.9'},
      ),
    );

    return webViewController;
  }

  NavigationDelegate _buildNavigationDelegate() {
    return NavigationDelegate(
      onNavigationRequest: _onNavigationRequest,
      onPageStarted: _onPageStarted,
      onPageFinished: _onPageFinished,
      onProgress: _onProgress,
      onWebResourceError: _onWebResourceError,
      onHttpError: _onHttpError,
    );
  }

  /// Only the reader's own top-level navigation is redirected out; everything
  /// inside the document is left to the page.
  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    if (!request.isMainFrame) return NavigationDecision.navigate;

    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;

    final scheme = uri.scheme.toLowerCase();
    final allowed =
        (scheme == 'http' || scheme == 'https') &&
        _controller.allowedNavigationHosts.contains(uri.host.toLowerCase());

    if (allowed) return NavigationDecision.navigate;

    // A link the reader cannot follow is handed to the browser rather than
    // dropped, which is what "prevented" would otherwise mean silently:
    // off-site articles, and the mailto:/tel: links a writer embeds.
    unawaited(_openExternally(request.url));

    return NavigationDecision.prevent;
  }

  void _onPageStarted(String url) {
    _mainFrameUrl = url;
    appLog('WebView.onPageStarted: url=$url');

    _controller.onPageStart(url);

    // The document-start scripts the old plugin ran through user scripts have
    // no equivalent in the official plugin, so they are injected as early as
    // the platform allows. Anything that arrives too late for a first paint is
    // re-applied once the page finishes.
    unawaited(_injectDocumentStartScripts());
  }

  Future<void> _injectDocumentStartScripts() async {
    for (final source in _documentScripts()) {
      try {
        await _webViewController.runJavaScript(source);
      } catch (error) {
        // The document may not exist yet when the navigation has only just
        // started; the page-finished pass re-applies everything that matters.
        appLog(
          'Could not inject early script: $error',
          name: 'Reader',
          level: LogLevel.warning,
        );
      }
    }
  }

  void _onPageFinished(String url) {
    _mainFrameUrl = url;
    unawaited(_handlePageFinished(url));
  }

  Future<void> _handlePageFinished(String url) async {
    appLog('WebView.onPageFinished: url=$url');

    // The loader is dismissed before the article is reported ready, so the
    // reader is not held behind a loading indicator for a page that has
    // already finished.
    _controller.onPageLoaded();
    await _controller.injectCustomCSS();
  }

  void _onProgress(int progress) {
    appLog('WebView.onProgress: progress=$progress');
    _controller.updateProgress(progress.toDouble());
  }

  void _onWebResourceError(WebResourceError error) {
    if (!(error.isForMainFrame ?? false)) return;

    appLog('WebView.onWebResourceError: ${error.description}');
    unawaited(_controller.onPageError(_describe(error.description)));
  }

  void _onHttpError(HttpResponseError error) {
    final requestUri = error.request?.uri;
    if (requestUri != null && !_isMainFrameRequest(requestUri)) return;

    final statusCode = error.response?.statusCode ?? 0;
    appLog('WebView.onHttpError: url=$requestUri, code=$statusCode');

    if (statusCode >= 500) {
      unawaited(_controller.handleServerError(statusCode));
    } else if (statusCode >= 400) {
      unawaited(
        _controller.onPageError(
          statusCode == 404
              ? 'Article not found (404).'
              : 'Server error ($statusCode)',
        ),
      );
    }
  }

  /// Whether an HTTP error belongs to the document rather than a subresource.
  bool _isMainFrameRequest(Uri uri) {
    final mainFrame = _mainFrameUrl;
    if (mainFrame == null) return true;

    final parsed = Uri.tryParse(mainFrame);
    if (parsed == null) return true;

    return parsed.replace(fragment: '').toString() ==
        uri.replace(fragment: '').toString();
  }

  void _onConsoleMessage(JavaScriptConsoleMessage message) {
    if (message.level == JavaScriptLogLevel.error) {
      appLog('Console: ${message.message}', name: 'Reader');
    }
  }

  /// Suppresses the page's own alert/confirm/prompt dialogs.
  Future<void> _onJavaScriptAlertDialog(JavaScriptAlertDialogRequest request) {
    return Future<void>.value();
  }

  Future<bool> _onJavaScriptConfirmDialog(
    JavaScriptConfirmDialogRequest request,
  ) {
    return Future<bool>.value(false);
  }

  Future<String> _onJavaScriptTextInputDialog(
    JavaScriptTextInputDialogRequest request,
  ) {
    return Future<String>.value('');
  }

  /// The scripts the reader wants in the document before its own code runs.
  List<String> _documentScripts() {
    return [
      ReaderTheme.earlyStyleInjector(
        settings: _controller.readingSettings.value,
        systemDark: _controller.isDarkMode,
      ),
      ReaderTheme.popupBlockingJs,
    ];
  }

  /// Opens [url] outside the reader, e.g. an off-site link the user tapped.
  Future<void> _openExternally(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (error) {
      // Nothing on the device can handle it (or the platform refused); there is
      // no reader-side fallback for that, so it is only logged.
      appLog(
        'Could not open $url: $error',
        name: 'Reader',
        level: LogLevel.warning,
      );
    }
  }

  /// Turns a WebView error into a message that tells the user what to try.
  static String _describe(String description) {
    final text = description.toLowerCase();

    if (text.contains('host') || text.contains('dns')) {
      return 'Cannot connect to server. Check your internet connection.';
    }
    if (text.contains('connect') || text.contains('network')) {
      return 'Connection failed. Please try again.';
    }
    if (text.contains('timeout') || text.contains('time')) {
      return 'Request timed out. Please try again.';
    }
    return 'Failed to load article: $description';
  }
}

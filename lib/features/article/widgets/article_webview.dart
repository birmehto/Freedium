import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

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

  PullToRefreshController? _pullToRefreshController;

  @override
  void initState() {
    super.initState();

    // Pull-to-refresh is only implemented for Android in this plugin.
    if (defaultTargetPlatform == TargetPlatform.android) {
      _pullToRefreshController = PullToRefreshController(
        // Ends the indicator unconditionally: `requestRefresh` can return
        // without loading anything (no WebView yet, no mirror available), and
        // the spinner would otherwise stay on screen forever.
        onRefresh: () async {
          try {
            await _controller.requestRefresh();
          } finally {
            await _endRefreshing();
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _pullToRefreshController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialSettings = InAppWebViewSettings(
      userAgent: _readerUserAgent,
      supportZoom: false,
      useShouldOverrideUrlLoading: true,
      mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
      // The reader is a scroller, not a bounce-scroller: the stylesheet already
      // declares `overscroll-behavior-y: none`. Leaving the default would also
      // make the plugin flip the WebView's overscroll mode twice on every
      // overscroll near the top of the article, invalidating the view mid-gesture.
      overScrollMode: OverScrollMode.NEVER,
    );

    final initialUserScripts = UnmodifiableListView<UserScript>([
      UserScript(
        source: ReaderTheme.esCompatPolyfills,
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      ),
      UserScript(
        source: ReaderTheme.earlyStyleInjector(
          settings: _controller.readingSettings.value,
          systemDark: _controller.isDarkMode,
        ),
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      ),
      UserScript(
        source: ReaderTheme.popupBlockingJs,
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      ),
    ]);

    return InAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri(widget.url),
        headers: const {'Accept-Language': 'en-US,en;q=0.9'},
      ),
      initialSettings: initialSettings,
      initialUserScripts: initialUserScripts,
      pullToRefreshController: _pullToRefreshController,
      onWebViewCreated: _controller.setWebViewController,
      onCreateWindow: (controller, createWindowAction) async => false,
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final requestUrl = navigationAction.request.url;
        if (requestUrl == null) return NavigationActionPolicy.CANCEL;

        // Only the reader's own top-level navigation is redirected out;
        // everything inside the document is left to the page.
        final isMainFrame = navigationAction.targetFrame?.isMainFrame ?? true;
        if (!isMainFrame) return NavigationActionPolicy.ALLOW;

        final scheme = requestUrl.scheme.toLowerCase();
        final allowed =
            (scheme == 'http' || scheme == 'https') &&
            _controller.allowedNavigationHosts.contains(
              requestUrl.host.toLowerCase(),
            );

        if (allowed) return NavigationActionPolicy.ALLOW;

        // A link the reader cannot follow is handed to the browser rather than
        // dropped, which is what "cancelled" would otherwise mean silently:
        // off-site articles, and the mailto:/tel: links a writer embeds.
        unawaited(_openExternally(requestUrl.toString()));

        return NavigationActionPolicy.CANCEL;
      },
      onPermissionRequest: (controller, permissionRequest) async =>
          PermissionResponse(),
      onJsAlert: (controller, jsAlertRequest) async =>
          JsAlertResponse(handledByClient: true),
      onJsConfirm: (controller, jsConfirmRequest) async =>
          JsConfirmResponse(handledByClient: true),
      onJsPrompt: (controller, jsPromptRequest) async =>
          JsPromptResponse(value: '', handledByClient: true),
      onJsBeforeUnload: (controller, jsBeforeUnloadRequest) async =>
          JsBeforeUnloadResponse(
            action: JsBeforeUnloadResponseAction.CANCEL,
            handledByClient: true,
          ),
      onLoadStart: (controller, url) {
        appLog('WebView.onLoadStart: url=$url');
        _controller.onPageStart(url?.toString());
      },
      onPageCommitVisible: (controller, url) {
        appLog('WebView.onPageCommitVisible: url=$url');
        _controller.onPageCommitVisible();
      },
      onLoadStop: (controller, url) async {
        appLog('WebView.onLoadStop: url=$url');

        // The loader is dismissed before the pull-to-refresh spinner is, not
        // after: ending the refresh can take a moment, and the reader should not
        // be held behind a loading indicator for an article that has finished.
        _controller.onPageLoaded();
        await _endRefreshing();
        await _controller.injectCustomCSS();
      },
      onScrollChanged: (controller, x, y) {
        // Deliberately not logged: scrolling fires hundreds of times per
        // article. The offset alone cannot express "how far through" anyway, so
        // the controller measures the document once the scrolling settles.
        _controller.reportScroll();
      },
      onProgressChanged: (controller, progress) {
        appLog('WebView.onProgressChanged: progress=$progress');
        _controller.updateProgress(progress.toDouble());
      },
      onReceivedError: (controller, request, error) {
        if (request.isForMainFrame ?? false) {
          appLog('WebView.onReceivedError: ${error.description}');
          unawaited(_endRefreshing());
          unawaited(_controller.onPageError(_describe(error.description)));
        }
      },
      onReceivedHttpError: (controller, request, errorResponse) {
        if (!(request.isForMainFrame ?? false)) return;
        appLog(
          'WebView.onReceivedHttpError: url=${request.url}, code=${errorResponse.statusCode}',
        );
        final statusCode = errorResponse.statusCode ?? 0;
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
      },
      onConsoleMessage: (controller, consoleMessage) {
        if (consoleMessage.messageLevel == ConsoleMessageLevel.ERROR) {
          appLog('Console: ${consoleMessage.message}', name: 'Reader');
        }
      },
    );
  }

  Future<void> _endRefreshing() async {
    await _pullToRefreshController?.endRefreshing();
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

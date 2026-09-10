import 'dart:io';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/app/app_log.dart';
import '../controllers/article_controller.dart';

class ArticleWebView extends GetView<ArticleController> {
  const ArticleWebView({required this.url, super.key});
  final String url;

  @override
  Widget build(BuildContext context) {
    appLog('Building ArticleWebView for URL: $url');

    final initialSettings = InAppWebViewSettings(
      userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      builtInZoomControls: Platform.isAndroid ? false : null,
      allowsInlineMediaPlayback: true,
      mediaPlaybackRequiresUserGesture: false,
      useShouldOverrideUrlLoading: true,
      mixedContentMode: Platform.isAndroid
          ? MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW
          : null,
    );

    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(url)),
      initialSettings: initialSettings,
      onWebViewCreated: (webViewController) {
        controller.setWebViewController(webViewController);
        appLog('WebView created for URL: $url');
      },
      onLoadStart: (controller, url) {
        this.controller.isLoading.value = true;
        this.controller.errorMessage.value = '';
        if (url != null) {
          this.controller.currentUrl.value = url.toString();
        }
        appLog('Page started loading: ${url?.toString()}');
      },
      onLoadStop: (controller, url) async {
        appLog('Page finished loading: ${url?.toString()}');

        // Small delay before marking as loaded
        await Future.delayed(const Duration(milliseconds: 100));
        this.controller.onPageLoaded();
        this.controller.injectCustomCSS();
      },
      onScrollChanged: (controller, x, y) {
        this.controller.handleScroll(y);
      },
      onProgressChanged: (controller, progress) {
        this.controller.updateProgress(progress.toDouble());
        appLog('Page loading progress: $progress%');
      },
      onReceivedError: (controller, request, error) {
        appLog(
          'Page error: ${error.description}, type: ${error.type}, for: ${request.url}',
        );

        // Only handle main frame errors
        if (request.isForMainFrame ?? false) {
          String errorMsg = 'Failed to load article';

          final description = error.description.toLowerCase();
          if (description.contains('host') || description.contains('dns')) {
            errorMsg =
                'Cannot connect to server. Check your internet connection.';
          } else if (description.contains('connect') ||
              description.contains('network')) {
            errorMsg = 'Connection failed. Please try again.';
          } else if (description.contains('timeout') ||
              description.contains('time')) {
            errorMsg = 'Request timed out. Please try again.';
          } else {
            errorMsg = 'Failed to load article: ${error.description}';
          }

          this.controller.onPageError(errorMsg);
        }
      },
      onReceivedHttpError: (controller, request, errorResponse) {
        if (request.isForMainFrame ?? false) {
          appLog(
            'HTTP Error: ${errorResponse.statusCode} ${errorResponse.reasonPhrase} for ${request.url}',
          );

          final statusCode = errorResponse.statusCode ?? 0;

          if (statusCode >= 500) {
            this.controller.handleServerError(statusCode);
          } else if (statusCode >= 400) {
            String errorMsg = 'Server error ($statusCode)';

            if (statusCode == 404) {
              errorMsg = 'Article not found (404).';
            }

            this.controller.onPageError(errorMsg);
          }
        }
      },

      onConsoleMessage: (controller, consoleMessage) {
        appLog(
          'Console: ${consoleMessage.messageLevel}: ${consoleMessage.message}',
        );
      },
    );
  }
}

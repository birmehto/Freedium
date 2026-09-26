import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/app_log.dart';
import '../controllers/login_controller.dart';

/// Hosts Medium's own sign-in page.
///
/// The reader's credentials are entered into Medium's page and never pass
/// through Dart, so there is nothing for the app to hold, leak or mishandle.
class LoginWebView extends StatefulWidget {
  const LoginWebView({required this.url, super.key});

  /// The first URL to load: the sign-in page, or the profile when a session is
  /// already restored.
  ///
  /// Read once when the WebView is created. Later navigations are driven by the
  /// controller, so this widget is never rebuilt just because the loaded URL
  /// changed.
  final String url;

  @override
  State<LoginWebView> createState() => _LoginWebViewState();
}

class _LoginWebViewState extends State<LoginWebView> {
  late final LoginController _controller = Get.find<LoginController>();

  @override
  void dispose() {
    _controller.webViewController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(widget.url)),
      initialSettings: InAppWebViewSettings(
        // Medium's login is a mobile-first form; leaving the default agent
        // avoids the desktop layout the mirrors need but the reader does not.
        useShouldOverrideUrlLoading: true,
        // Sign-in is a flow of pages, not a single document: identity providers
        // open their own windows, and closing them would abandon the flow.
        supportMultipleWindows: true,
      ),
      onWebViewCreated: _controller.setWebViewController,
      onCreateWindow: (controller, createWindowAction) async {
        final url = createWindowAction.request.url;
        if (url == null) return false;

        final policy = _controller.resolveNavigation(url);
        if (policy != NavigationActionPolicy.ALLOW) return false;

        await controller.loadUrl(urlRequest: URLRequest(url: url));
        return true;
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final isMainFrame = navigationAction.targetFrame?.isMainFrame ?? true;

        return _controller.resolveNavigation(
          navigationAction.request.url,
          isMainFrame: isMainFrame,
        );
      },
      onPermissionRequest: (controller, permissionRequest) async =>
          PermissionResponse(),
      onJsAlert: (controller, jsAlertRequest) async =>
          JsAlertResponse(handledByClient: true),
      onJsConfirm: (controller, jsConfirmRequest) async =>
          JsConfirmResponse(handledByClient: true),
      onLoadStart: (controller, url) =>
          _controller.onPageStart(url?.toString()),
      onLoadStop: (controller, url) {
        appLog('Login.onLoadStop: url=$url', name: 'Account');
        _controller.onPageLoaded();
      },
      onProgressChanged: (controller, progress) =>
          _controller.updateProgress(progress.toDouble()),
      onReceivedError: (controller, request, error) {
        if (!(request.isForMainFrame ?? false)) return;

        appLog('Login.onReceivedError: ${error.description}', name: 'Account');
        _controller.onPageError(error.description);
      },
      onConsoleMessage: (controller, consoleMessage) =>
          _controller.onConsoleMessage(consoleMessage),
    );
  }
}

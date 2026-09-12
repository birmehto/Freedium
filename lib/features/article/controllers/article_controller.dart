import 'dart:async';
import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/reader_theme.dart';
import '../../../../core/services/clipboard_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/utils/url_validator.dart';
import '../../../core/utils/app_log.dart';
import '../../favorites/models/favorite_article.dart';

class ArticleController extends GetxController {
  final ClipboardService _clipboardService = Get.find();
  final StorageService _storage = Get.find();
  final ThemeService _themeService = Get.find();

  final currentUrl = ''.obs;
  final originalUrl = ''.obs;
  final errorMessage = ''.obs;
  final isLoading = true.obs;
  final isInitialLoad = true.obs;
  final loadingProgress = 0.0.obs;
  final scrollProgress = 0.0.obs;

  Timer? _loadingTimer;

  final isFavorite = false.obs;

  bool get isDarkMode => _themeService.isDarkMode.value;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments as Map<String, dynamic>?;
    final url = args?['url'] as String?;
    final original = args?['originalUrl'] as String?;

    if (url == null || !UrlValidator.isValidUrl(url)) {
      errorMessage.value = 'Invalid or missing article URL';
      isLoading.value = false;
      return;
    }

    _initialize(url, original);
    _setupWebViewListeners();
  }

  void _initialize(String url, String? original) {
    currentUrl.value = url;
    originalUrl.value = original ?? url;
    errorMessage.value = '';
    isLoading.value = true;
    isInitialLoad.value = true;
    loadingProgress.value = 0.0;
    _startLoadingTimer();

    isFavorite.value = _storage.isFavorite(originalUrl.value);
  }

  void onPageLoaded() {
    _cancelLoadingTimer();
    isLoading.value = false;
    isInitialLoad.value = false;
    loadingProgress.value = 1.0;
    _refreshLayoutMetrics();
  }

  void handleServerError(int statusCode) {
    String errorMsg = 'Server error ($statusCode)';
    if (statusCode == 502) errorMsg = 'Bad Gateway (502). Server unavailable.';
    if (statusCode == 503) errorMsg = 'Service Unavailable (503).';
    onPageError(errorMsg);
  }

  void onPageError(String message) {
    _cancelLoadingTimer();
    errorMessage.value = message;
    isLoading.value = false;
    isInitialLoad.value = false;
    loadingProgress.value = 0.0;
  }

  void updateProgress(double progress) {
    loadingProgress.value = progress / 100.0;
  }

  double? _contentHeight;
  double? _viewportHeight;

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
        // Document is not scrollable yet (e.g. images still loading after CSS
        // injection). Re-measure shortly so the scroll bar can catch up.
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!isClosed) {
            unawaited(_refreshLayoutMetrics());
          }
        });
      }
    } catch (e) {
      appLog(e.toString());
    }
  }

  void handleScroll(int y) {
    if (isClosed || webViewController == null) return;

    if (_contentHeight == null ||
        _viewportHeight == null ||
        _contentHeight! <= _viewportHeight!) {
      unawaited(_refreshLayoutMetrics());
    }
    final scrollable = (_contentHeight ?? 0.0) - (_viewportHeight ?? 0.0);
    scrollProgress.value = scrollable > 0
        ? (y / scrollable).clamp(0.0, 1.0)
        : 0.0;
  }

  void requestRefresh() {
    errorMessage.value = '';
    isLoading.value = true;
    loadingProgress.value = 0.0;
    _startLoadingTimer();
    webViewController?.reload();
  }

  Future<void> shareArticle() async {
    if (originalUrl.isEmpty) return;
    SharePlus.instance.share(
      ShareParams(uri: Uri.parse(originalUrl.value), subject: articleTitle),
    );
  }

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
      await _storage.removeFromFavorites(url);
      isFavorite.value = false;
    } else {
      await _storage.addToFavorites(
        FavoriteArticle(
          title: articleTitle,
          url: url,
          visitedAt: DateTime.now(),
          author: articleAuthor,
          domain: articleDomain,
        ).toJson(),
      );
      isFavorite.value = true;
    }
  }

  String get articleTitle {
    final uri = Uri.tryParse(originalUrl.value);
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

  String? get articleDomain {
    final uri = Uri.tryParse(originalUrl.value);
    if (uri != null) {
      String host = uri.host;
      if (host.startsWith('www.')) host = host.substring(4);
      return host;
    }
    return null;
  }

  String? get articleAuthor {
    final uri = Uri.tryParse(originalUrl.value);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      final firstSegment = uri.pathSegments.first;
      if (firstSegment.startsWith('@')) {
        return firstSegment
            .substring(1)
            .replaceAll('-', ' ')
            .split(' ')
            .map(
              (word) => word.isNotEmpty
                  ? '${word[0].toUpperCase()}${word.substring(1)}'
                  : word,
            )
            .join(' ');
      }
    }
    return null;
  }

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
    super.onClose();
  }

  InAppWebViewController? webViewController;

  void setWebViewController(InAppWebViewController controller) {
    webViewController = controller;
  }

  void _setupWebViewListeners() {
    ever(_themeService.isDarkMode, (_) => injectCustomCSS());
  }

  Future<void> injectCustomCSS() async {
    if (isClosed || webViewController == null) return;

    final css = ReaderTheme.getCss(isDarkMode: isDarkMode);

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
      _refreshLayoutMetrics();
    } catch (e) {
      appLog('Error injecting CSS: $e');
    }
  }
}

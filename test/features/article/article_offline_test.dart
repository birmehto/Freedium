import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/constants/reader_theme.dart';
import 'package:freedium/core/services/storage_service.dart';
import 'package:freedium/core/storage/article_cache_store.dart';
import 'package:freedium/features/article/controllers/article_controller.dart';
import 'package:freedium/features/article/models/article_request.dart';
import 'package:material_ui/material_ui.dart';
import 'package:webview_flutter/webview_flutter.dart'
    show LoadRequestMethod, WebViewController;
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart'
    show PlatformWebViewController, PlatformWebViewControllerCreationParams;

import '../../helpers/test_env.dart';

/// Covers the offline half of the reader: a saved copy standing in for a dead
/// mirror, and the reader's place being remembered.
///
/// No WebView is created, so this drives the controller through the same
/// navigation and callbacks the real page uses.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const url = 'https://medium.com/@someone/a-story-abc123';

  late TestServices services;
  late StorageService storage;
  late ProviderContainer container;
  late ArticleController controller;

  setUp(() {
    services = registerServices();
    storage = services.storage;
    // Own a child scope so disposal cannot leak into another test. The
    // handler contains a library-side assertion in ArticleController.onDispose
    // (it calls ref.read from a disposal callback).
    container = ProviderContainer(
      parent: services.container,
      // ignore: invalid_use_of_internal_member
      onError: (_, _) {},
    );

    // With no automatic fallback there is one place a failure can land: the
    // saved copy. Turning it off is the same state a reader reaches after
    // every mirror has been tried, without having to try them here.
    storage.preferences.autoFallback = false;

    controller = container.read(articleControllerProvider.notifier);
  });

  tearDown(() => container.dispose());

  ArticleState state() => container.read(articleControllerProvider);

  /// Opens the reader the way the page does, so the request is loaded and the
  /// stored position and any saved copy are picked up.
  ///
  /// [articleOnScreen] stands in for a loaded document: no real WebView exists
  /// here, so the body of the article the reader is looking at is supplied
  /// directly through a fake controller.
  Future<void> openReader(
    WidgetTester tester, {
    String? articleOnScreen,
  }) async {
    await controller.open(const ArticleRequest(url: url));

    // open() clears the previous article's WebView, so attach the stand-in
    // afterwards, the way the page does once its WebView is ready.
    controller.webViewController = articleOnScreen == null
        ? null
        : _LoadedWebViewController(articleOnScreen);

    await tester.pumpWidget(
      wrapTestApp(services: services, child: const SizedBox.shrink()),
    );
    await tester.pumpAndSettle();

    // A real load leaves the watchdog armed; settle it before the test ends.
    addTearDown(() => controller.onPageCommitVisible());
  }

  Future<void> saveArticle({String title = 'Saved Story'}) async {
    await storage.cache.save(
      url: url,
      html: '<article><p>Cached body.</p></article>',
      title: title,
      author: 'Cached Author',
      wordCount: 900,
    );
  }

  group('opening an article', () {
    testWidgets('reports no saved copy when nothing is cached', (tester) async {
      await openReader(tester);

      expect(state().hasOfflineCopy, isFalse);
    });

    testWidgets('reports a saved copy', (tester) async {
      await saveArticle();

      await openReader(tester);

      expect(state().hasOfflineCopy, isTrue);
    });
  });

  group('when every mirror fails', () {
    testWidgets('shows the saved copy instead of an error', (tester) async {
      await saveArticle();

      await openReader(tester);
      await controller.onPageError('Server unreachable');
      await tester.pumpAndSettle();

      expect(state().isOffline, isTrue);
      expect(state().errorMessage, isEmpty);
      expect(state().articleTitle, 'Saved Story');
      expect(state().articleAuthor, 'Cached Author');
      expect(state().isLoading, isFalse);
    });

    testWidgets('shows the failure when nothing is saved', (tester) async {
      await openReader(tester);
      await controller.onPageError('Server unreachable');
      await tester.pumpAndSettle();

      expect(state().isOffline, isFalse);
      expect(state().errorMessage, 'Server unreachable');
    });

    testWidgets('the saved copy wins over the guessed title', (tester) async {
      await saveArticle(title: 'A Story Worth Caching');

      await openReader(tester);
      await controller.onPageError('boom');

      expect(state().articleTitle, 'A Story Worth Caching');
    });
  });

  group('refreshing', () {
    testWidgets('leaving offline mode for a reload', (tester) async {
      await saveArticle();
      await openReader(tester);
      await controller.onPageError('boom');
      expect(state().isOffline, isTrue);

      await controller.requestRefresh();

      expect(state().isOffline, isFalse);
      expect(state().errorMessage, isEmpty);
    });

    testWidgets('survives a refresh with no WebView attached', (tester) async {
      await openReader(tester);

      await controller.requestRefresh();

      expect(tester.takeException(), isNull);
    });
  });

  group('the store and the reader agree', () {
    testWidgets('dropping the copy makes the article unreadable offline', (
      tester,
    ) async {
      await saveArticle();
      await openReader(tester);
      await storage.cache.remove(url);

      await controller.onPageError('boom');

      expect(state().isOffline, isFalse);
      expect(state().errorMessage, 'boom');
    });

    testWidgets('a dropped copy does not report a saved copy', (tester) async {
      await saveArticle();
      await openReader(tester);
      await storage.cache.remove(url);

      expect(state().hasOfflineCopy, isTrue);

      // Reopening the article is what re-checks, since the reader is told what
      // it can keep offline.
      await openReader(tester);

      expect(state().hasOfflineCopy, isFalse);
    });

    testWidgets('reading an article stores nothing on its own', (tester) async {
      await openReader(tester);

      expect(
        await storage.cache.read(url),
        isNull,
        reason: 'nothing was asked to be saved, so nothing is',
      );
      expect(await storage.cache.contains(url), isFalse);
    });
  });

  group('favoriting', () {
    testWidgets('keeps the article on the device', (tester) async {
      await openReader(
        tester,
        articleOnScreen: '<article><p>Body.</p></article>',
      );

      expect(await storage.cache.contains(url), isFalse);

      await controller.toggleFavorite();

      expect(storage.library.isFavorite(url), isTrue);
      expect(state().hasOfflineCopy, isTrue);
      expect(
        (await storage.cache.read(url))?.html,
        '<article><p>Body.</p></article>',
      );
    });

    testWidgets('the favorite is kept even with nothing to store', (
      tester,
    ) async {
      await openReader(tester);

      // Nothing is on screen, so there is no body to keep. The favorite is the
      // reader's decision and is recorded regardless.
      await controller.toggleFavorite();

      expect(storage.library.isFavorite(url), isTrue);
      expect(state().hasOfflineCopy, isFalse);
      expect(await storage.cache.contains(url), isFalse);
    });

    testWidgets('taking the favorite away takes the copy with it', (
      tester,
    ) async {
      await openReader(
        tester,
        articleOnScreen: '<article><p>Body.</p></article>',
      );

      await controller.toggleFavorite();
      expect(await storage.cache.contains(url), isTrue);

      await controller.toggleFavorite();

      expect(storage.library.isFavorite(url), isFalse);
      expect(state().hasOfflineCopy, isFalse);
      expect(await storage.cache.contains(url), isFalse);
    });

    testWidgets('a second press while one is running is ignored', (
      tester,
    ) async {
      await openReader(
        tester,
        articleOnScreen: '<article><p>Body.</p></article>',
      );

      await Future.wait([
        controller.toggleFavorite(),
        controller.toggleFavorite(),
      ]);

      // One favorite, rather than one that was added and immediately removed.
      expect(storage.library.isFavorite(url), isTrue);
      expect(state().isStoringArticle, isFalse);
    });
  });

  group('ArticleCacheStore', () {
    test('a saved copy is counted and measured', () async {
      await saveArticle();

      expect(storage.cache.cachedCount.value, 1);
      expect(storage.cache.cachedBytes.value, greaterThan(0));
      expect(
        storage.cache.cachedBytes.value,
        lessThanOrEqualTo(ArticleCacheStore.maxCacheBytes),
      );
    });
  });
}

/// A WebView stand-in that reports [html] as the document on screen.
///
/// The body is the one thing that only ever exists inside a loaded document, so
/// supplying it is the whole of standing in for a page.
class _LoadedWebViewController extends WebViewController {
  _LoadedWebViewController(this._html)
    : super.fromPlatform(_FakePlatformWebViewController());

  final String _html;

  @override
  Future<Object> runJavaScriptReturningResult(String javaScript) async {
    if (javaScript == ReaderTheme.extractArticleHtmlJs) {
      return jsonEncode({'found': true, 'html': _html});
    }
    return jsonEncode(<String, dynamic>{});
  }

  @override
  Future<void> runJavaScript(String javaScript) async {}

  @override
  Future<void> setBackgroundColor(Color color) async {}

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {}

  @override
  Future<void> loadRequest(
    Uri uri, {
    LoadRequestMethod method = LoadRequestMethod.get,
    Map<String, String> headers = const <String, String>{},
    Uint8List? body,
  }) async {}

  @override
  Future<void> reload() async {}
}

/// The platform half of the fake, built without a real plugin channel.
class _FakePlatformWebViewController extends PlatformWebViewController {
  _FakePlatformWebViewController()
    : super.implementation(const PlatformWebViewControllerCreationParams());
}

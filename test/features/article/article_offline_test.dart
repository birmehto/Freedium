import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/network/article_resolver.dart';
import 'package:freedium/core/routes/app_routes.dart';
import 'package:freedium/core/services/clipboard_service.dart';
import 'package:freedium/core/services/storage_service.dart';
import 'package:freedium/core/services/theme_service.dart';
import 'package:freedium/core/storage/article_cache_store.dart';
import 'package:freedium/features/article/controllers/article_controller.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart' as ui;

import '../../helpers/test_env.dart';

/// Covers the offline half of the reader: a saved copy standing in for a dead
/// mirror, and the reader's place being remembered.
///
/// No WebView is created, so this drives the controller through the same
/// navigation and callbacks the real page uses.
void main() {
  const url = 'https://medium.com/@someone/a-story-abc123';

  late StorageService storage;
  late ArticleController controller;

  setUp(() {
    Get.testMode = true;
    final services = registerServices();
    storage = services.storage;

    // With no automatic fallback there is one place a failure can land: the
    // saved copy. Turning it off is the same state a reader reaches after
    // every mirror has been tried, without having to try them here.
    storage.preferences.autoFallback = false;
  });

  tearDown(Get.reset);

  /// Opens the reader the way navigation does, so `onInit` runs with real route
  /// arguments and loads the stored position and any saved copy.
  ///
  /// [articleOnScreen] stands in for a loaded document: no WebView exists here,
  /// so the body of the article the reader is looking at is supplied directly.
  Future<void> openReader(
    WidgetTester tester, {
    String? articleOnScreen,
  }) async {
    // A reader left open would still be built after its services are gone.
    if (Get.isRegistered<ArticleController>()) {
      Get.back();
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(
      M3ETheme(
        data: M3EThemeData.light(seedColor: testSeedColor),
        child: GetMaterialApp(
          localizationsDelegates: const [
            ui.DefaultMaterialLocalizations.delegate,
          ],
          initialRoute: AppRoutes.home,
          getPages: [
            GetPage(
              name: AppRoutes.home,
              page: () => const Scaffold(body: Text('home')),
            ),
            GetPage(
              name: AppRoutes.article,
              page: () => const Scaffold(body: Text('reader')),
              binding: BindingsBuilder(() {
                Get.put(_buildReader(articleOnScreen));
              }),
            ),
          ],
        ),
      ),
    );

    // Not awaited: the route stays open, like it does when a reader is in it.
    Get.toNamed<void>(
      AppRoutes.article,
      arguments: {'url': url, 'originalUrl': url},
    );
    await tester.pumpAndSettle();

    controller = Get.find<ArticleController>();

    addTearDown(() async {
      if (Get.isRegistered<ArticleController>()) {
        Get.back();
        await tester.pumpAndSettle();
      }

      // Unmounting before the next test's services are torn down.
      await tester.pumpWidget(const SizedBox.shrink());
    });
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

      expect(controller.hasOfflineCopy.value, isFalse);
    });

    testWidgets('reports a saved copy', (tester) async {
      await saveArticle();

      await openReader(tester);

      expect(controller.hasOfflineCopy.value, isTrue);
    });
  });

  group('when every mirror fails', () {
    testWidgets('shows the saved copy instead of an error', (tester) async {
      await saveArticle();

      await openReader(tester);
      await controller.onPageError('Server unreachable');
      await tester.pumpAndSettle();

      expect(controller.isOffline.value, isTrue);
      expect(controller.errorMessage.value, isEmpty);
      expect(controller.articleTitle.value, 'Saved Story');
      expect(controller.articleAuthor.value, 'Cached Author');
      expect(controller.isLoading.value, isFalse);
    });

    testWidgets('shows the failure when nothing is saved', (tester) async {
      await openReader(tester);
      await controller.onPageError('Server unreachable');
      await tester.pumpAndSettle();

      expect(controller.isOffline.value, isFalse);
      expect(controller.errorMessage.value, 'Server unreachable');
    });

    testWidgets('the saved copy wins over the guessed title', (tester) async {
      await saveArticle(title: 'A Story Worth Caching');

      await openReader(tester);
      await controller.onPageError('boom');

      expect(controller.articleTitle.value, 'A Story Worth Caching');
    });
  });

  group('refreshing', () {
    testWidgets('leaving offline mode for a reload', (tester) async {
      await saveArticle();
      await openReader(tester);
      await controller.onPageError('boom');
      expect(controller.isOffline.value, isTrue);

      await controller.requestRefresh();

      expect(controller.isOffline.value, isFalse);
      expect(controller.errorMessage.value, isEmpty);
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

      expect(controller.isOffline.value, isFalse);
      expect(controller.errorMessage.value, 'boom');
    });

    testWidgets('a dropped copy does not report a saved copy', (tester) async {
      await saveArticle();
      await openReader(tester);
      await storage.cache.remove(url);

      expect(controller.hasOfflineCopy.value, isTrue);

      // Reopening the article is what re-checks, since the reader is told what
      // it can keep offline.
      await openReader(tester);

      expect(controller.hasOfflineCopy.value, isFalse);
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
      expect(controller.hasOfflineCopy.value, isTrue);
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
      expect(controller.hasOfflineCopy.value, isFalse);
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
      expect(controller.hasOfflineCopy.value, isFalse);
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
      expect(controller.isStoringArticle.value, isFalse);
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

/// A reader with an article on screen, without a WebView behind it.
///
/// The body is the one thing that only ever exists inside a loaded document, so
/// supplying it is the whole of standing in for a page.
class _LoadedArticleController extends ArticleController {
  _LoadedArticleController(
    this._html,
    ClipboardService clipboard,
    StorageService storage,
    ThemeService theme,
    ArticleResolver resolver,
  ) : super(clipboard, storage, theme, resolver);

  final String _html;

  @override
  Future<String?> readArticleHtml() async => _html;
}

/// The reader the article route registers.
///
/// With [articleOnScreen] set, the reader has a document to store, which a real
/// one only gets from the WebView this suite never builds.
ArticleController _buildReader(String? articleOnScreen) {
  final clipboard = ClipboardService()..onInit();
  final storage = Get.find<StorageService>();
  final theme = Get.find<ThemeService>();
  final resolver = Get.find<ArticleResolver>();

  if (articleOnScreen == null) {
    return ArticleController(clipboard, storage, theme, resolver);
  }
  return _LoadedArticleController(
    articleOnScreen,
    clipboard,
    storage,
    theme,
    resolver,
  );
}

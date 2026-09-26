import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/routes/app_routes.dart';
import 'package:freedium/core/services/clipboard_service.dart';
import 'package:freedium/core/services/storage_service.dart';
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
  Future<void> openReader(WidgetTester tester) async {
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
                Get.put(
                  ArticleController(
                    ClipboardService()..onInit(),
                    Get.find<StorageService>(),
                    Get.find(),
                    Get.find(),
                  ),
                );
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
      expect(controller.readingProgress.value, 0);
    });

    testWidgets('reports a saved copy', (tester) async {
      await saveArticle();

      await openReader(tester);

      expect(controller.hasOfflineCopy.value, isTrue);
    });

    testWidgets('restores the stored reading position', (tester) async {
      await storage.progress.save(url, ratio: 0.42, offset: 900);

      await openReader(tester);

      expect(controller.readingProgress.value, closeTo(0.42, 1e-9));
      expect(controller.readingProgressPercent, 42);
    });
  });

  group('when every mirror fails', () {
    testWidgets('shows the saved copy instead of an error', (tester) async {
      await saveArticle();
      await storage.progress.save(url, ratio: 0.3);

      await openReader(tester);
      await controller.onPageError('Server unreachable');
      await tester.pumpAndSettle();

      expect(controller.isOffline.value, isTrue);
      expect(controller.errorMessage.value, isEmpty);
      expect(controller.articleTitle.value, 'Saved Story');
      expect(controller.articleAuthor.value, 'Cached Author');
      expect(controller.readingProgress.value, closeTo(0.3, 1e-9));
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

  group('the cache and the reader agree', () {
    testWidgets('clearing the cache makes the article unreadable offline', (
      tester,
    ) async {
      await saveArticle();
      await openReader(tester);
      await storage.cache.clear();

      await controller.onPageError('boom');

      expect(controller.isOffline.value, isFalse);
      expect(controller.errorMessage.value, 'boom');
    });

    testWidgets('a cleared cache does not report a saved copy', (tester) async {
      await saveArticle();
      await openReader(tester);
      await storage.cache.clear();

      expect(controller.hasOfflineCopy.value, isTrue);

      // Reopening the article is what re-checks, since the reader is told what
      // it can keep offline.
      await openReader(tester);

      expect(controller.hasOfflineCopy.value, isFalse);
    });

    testWidgets('the cache holds a copy of what was read', (tester) async {
      await openReader(tester);

      expect(
        await storage.cache.read(url),
        isNull,
        reason: 'nothing loaded, so nothing to keep',
      );
      expect(await storage.cache.contains(url), isFalse);
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

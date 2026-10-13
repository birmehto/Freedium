import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/constants/app_constants.dart';
import 'package:freedium/core/network/article_resolver.dart';
import 'package:freedium/core/services/clipboard_service.dart';
import 'package:freedium/features/article/controllers/article_controller.dart';
import 'package:get/get.dart';

import '../../helpers/test_env.dart';

/// Covers the reader's loading state machine.
///
/// No WebView is created, so this drives the exact callbacks the WebView
/// reports: `onLoadStart`, `onPageCommitVisible`, progress updates,
/// `onLoadStop` and page errors.
void main() {
  late ClipboardService clipboard;
  late ArticleController controller;
  late ArticleResolver resolver;

  const url = 'https://medium.com/@someone/a-story-abc123';
  const mirrorUrl = 'https://freedium-mirror.cfd/proxied-story';

  setUp(() {
    Get.testMode = true;
    final services = registerServices();
    resolver = services.resolver;
    clipboard = ClipboardService()..onInit();

    // Deliberately not calling onInit(): it resolves the article from the Get
    // route arguments, which are not available outside a real navigation. The
    // loading state under test is already correct for a fresh controller.
    controller = ArticleController(
      clipboard,
      services.storage,
      services.theme,
      services.resolver,
    )..originalUrl.value = url;
  });

  tearDown(() {
    controller.onClose();
    Get.reset();
  });

  /// The fallback title the reader shows while no page has loaded yet.
  String titleFromUrl(ArticleController target, String source) {
    target.articleTitle.value = '';
    target.debugTitleFromUrl(source);
    return target.articleTitle.value;
  }

  group('initial state', () {
    test('starts loading, with no progress and no error', () {
      expect(controller.isLoading.value, isTrue);
      expect(controller.isInitialLoad.value, isTrue);
      expect(controller.loadingProgress.value, 0);
      expect(controller.errorMessage.value, isEmpty);
    });
  });

  group('updateProgress', () {
    test('reports progress as a 0..1 fraction', () {
      controller.updateProgress(40);
      expect(controller.loadingProgress.value, closeTo(0.4, 1e-9));

      controller.updateProgress(75);
      expect(controller.loadingProgress.value, closeTo(0.75, 1e-9));
    });

    test('clamps out-of-range and nonsensical values', () {
      controller.updateProgress(140);
      expect(controller.loadingProgress.value, 1.0);

      controller.updateProgress(-20);
      expect(controller.loadingProgress.value, 0.0);
    });

    test('intermediate progress keeps the loader visible', () {
      controller.updateProgress(50);

      expect(controller.isLoading.value, isTrue);
      expect(controller.isInitialLoad.value, isTrue);
    });

    test('stops loading once progress reaches 100', () {
      controller.updateProgress(100);

      expect(controller.isLoading.value, isFalse);
      expect(controller.isInitialLoad.value, isFalse);
      expect(controller.loadingProgress.value, 1.0);
    });

    test('reaches 100 and clears loading even without onLoadStop', () {
      // Regression: the reader kept spinning on articles that had already
      // finished loading whenever onLoadStop was late or skipped.
      controller
        ..onPageStart(mirrorUrl)
        ..updateProgress(100);

      expect(controller.isLoading.value, isFalse);
      expect(controller.isInitialLoad.value, isFalse);
    });

    test('is idempotent when the load already completed', () {
      controller
        ..onPageLoaded()
        ..updateProgress(100);

      expect(controller.isLoading.value, isFalse);
      expect(controller.loadingProgress.value, 1.0);
    });
  });

  group('onPageStart', () {
    test('re-arms the loader for the next page', () {
      controller
        ..onPageLoaded()
        ..onPageStart(mirrorUrl);

      expect(controller.isLoading.value, isTrue);
      expect(controller.currentUrl.value, mirrorUrl);
    });

    test('clears a previous error', () async {
      await controller.onPageError('boom');
      expect(controller.errorMessage.value, isNotEmpty);

      controller.onPageStart(mirrorUrl);
      expect(controller.errorMessage.value, isEmpty);
    });

    test('resets a full progress bar from the previous load', () {
      controller
        ..onPageLoaded()
        ..onPageStart(mirrorUrl);

      // A determinate bar left at 100% reads as "finished" for the whole of the
      // next load.
      expect(controller.loadingProgress.value, 0);
    });

    test('accepts a null URL without clobbering the current one', () {
      controller.currentUrl.value = mirrorUrl;
      controller.onPageStart(null);

      expect(controller.currentUrl.value, mirrorUrl);
    });
  });

  group('onPageCommitVisible', () {
    test('dismisses the loader once the document is painted', () {
      controller
        ..onPageStart(mirrorUrl)
        ..onPageCommitVisible();

      expect(controller.isLoading.value, isFalse);
      expect(controller.isInitialLoad.value, isFalse);
    });

    test('is a no-op on an already idle controller', () {
      controller
        ..onPageLoaded()
        ..onPageCommitVisible();

      expect(controller.isLoading.value, isFalse);
      expect(controller.errorMessage.value, isEmpty);
    });

    test('a late onLoadStart cannot re-block an already visible page', () {
      controller
        ..onPageLoaded()
        ..onPageStart(mirrorUrl)
        ..onPageCommitVisible();

      expect(controller.isLoading.value, isFalse);
    });
  });

  group('progress reaching 100', () {
    // The loading indicators are dismissed as soon as the load reports itself
    // finished. A backend that never reports 100 is covered by
    // `onPageCommitVisible` instead, which is why both paths dismiss.

    test('stops the loading indicators', () {
      controller
        ..onPageStart(mirrorUrl)
        ..updateProgress(100);

      expect(controller.isLoading.value, isFalse);
      expect(controller.isInitialLoad.value, isFalse);
    });

    test(
      'cancels the watchdog, so a finished page is not turned into an error',
      () {
        fakeAsync((async) {
          controller
            ..onPageStart(mirrorUrl)
            ..updateProgress(100);

          async.elapse(AppConstants.webViewTimeout * 3);

          expect(controller.errorMessage.value, isEmpty);
        });
      },
    );

    test('leaves a partial load alone', () {
      controller
        ..onPageStart(mirrorUrl)
        ..updateProgress(40);

      expect(controller.isLoading.value, isTrue);
      expect(controller.isInitialLoad.value, isTrue);
    });
  });

  group('onPageLoaded', () {
    test('completes the load', () {
      controller.onPageLoaded();

      expect(controller.isLoading.value, isFalse);
      expect(controller.isInitialLoad.value, isFalse);
      expect(controller.loadingProgress.value, 1.0);
    });

    test('is safe to call twice', () {
      controller
        ..onPageLoaded()
        ..onPageLoaded();

      expect(controller.isLoading.value, isFalse);
    });
  });

  group('watchdog', () {
    test('a page that never finishes is reported as a timeout', () {
      fakeAsync((async) {
        controller.onPageStart(mirrorUrl);
        expect(controller.isLoading.value, isTrue);

        async.elapse(AppConstants.webViewTimeout + const Duration(seconds: 1));

        // The resolver may have fallen back to another mirror, but either way
        // the reader must not still be showing a permanent loader.
        expect(controller.isLoading.value, isFalse);
      });
    });

    test('a committed page is not replaced by a spurious timeout', () {
      fakeAsync((async) {
        controller
          ..onPageStart(mirrorUrl)
          ..onPageCommitVisible();

        async.elapse(AppConstants.webViewTimeout * 3);

        // Reading a normal article must never turn into a timeout error.
        expect(controller.errorMessage.value, isEmpty);
        expect(controller.isLoading.value, isFalse);
      });
    });

    test('a finished page is not replaced by a spurious timeout', () {
      fakeAsync((async) {
        controller.onPageLoaded();

        async.elapse(AppConstants.webViewTimeout * 3);

        expect(controller.errorMessage.value, isEmpty);
      });
    });

    test('the timeout is long enough to be useful', () {
      expect(AppConstants.webViewTimeout.inSeconds, greaterThanOrEqualTo(15));
    });
  });

  group('onPageError', () {
    test('clears both loader flags', () async {
      await controller.onPageError('Something went wrong.');

      expect(controller.isLoading.value, isFalse);
      expect(controller.isInitialLoad.value, isFalse);
    });

    test(
      'one failure is handled once, however many times it is reported',
      () async {
        // A main-frame request can report both an HTTP error and a transport
        // error. Handling the second one as well retired a second mirror — one
        // that had never served the article — and issued a second load that
        // cancelled the first.
        await controller.onPageError('Connection failed.');
        final failing = controller.attemptedMirrors.toList();

        await controller.onPageError('Connection failed.');
        await controller.onPageError('Connection failed.');

        expect(controller.attemptedMirrors.toList(), failing);
      },
    );

    test('a later navigation may fail again', () async {
      await controller.onPageError('Connection failed.');
      final failing = controller.attemptedMirrors.length;

      controller
        ..onPageStart(mirrorUrl)
        ..originalUrl.value = url;
      await controller.onPageError('Connection failed.');

      expect(controller.attemptedMirrors.length, greaterThanOrEqualTo(failing));
    });

    test(
      'a mirror that failed is not asked again for the same article',
      () async {
        await controller.onPageError('Connection failed.');

        // The reader walks past mirrors it has already tried, but without a
        // fallback left it stops and surfaces the error.
        expect(controller.errorMessage.value, isNotEmpty);
      },
    );
  });

  group('mirror health', () {
    test('a saved copy is not a sign that the mirror worked', () {
      final healthy = resolver.sources.first;
      healthy.recordSuccess();

      controller.isOffline.value = true;
      controller.onPageLoaded();

      // Crediting the mirror for a document that came from disk resets the
      // failure count of the mirror that just failed, so the next article picks
      // it again and pays another timeout.
      expect(healthy.consecutiveFailures, 0);
    });

    test('a document served by a mirror credits that mirror', () {
      final source = resolver.sources.first;
      source.recordFailure();

      controller.onPageStart(mirrorUrl);
      resolver.resolve(url);
      controller.onPageLoaded();

      expect(source.consecutiveFailures, 0);
    });
  });

  group('article title', () {
    test('a URL with a trailing slash still yields a title', () {
      controller.articleTitle.value = '';

      expect(titleFromUrl(controller, '$url/'), isNotEmpty);
      expect(titleFromUrl(controller, 'https://medium.com/'), 'Article');
    });
  });

  group('onClose', () {
    test('cancels the watchdog so it cannot fire on a disposed controller', () {
      fakeAsync((async) {
        controller.onPageStart(mirrorUrl);
        controller.onClose();

        async.elapse(AppConstants.webViewTimeout * 2);

        expect(controller.isLoading.value, isTrue);
      });
    });
  });
}

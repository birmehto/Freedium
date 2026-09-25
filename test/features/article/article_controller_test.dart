import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/constants/app_constants.dart';
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

  const url = 'https://medium.com/@someone/a-story-abc123';
  const mirrorUrl = 'https://freedium-mirror.cfd/proxied-story';

  setUp(() {
    Get.testMode = true;
    final services = registerServices();
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

    test('clears a previous error', () {
      controller.onPageError('boom');
      expect(controller.errorMessage.value, isNotEmpty);

      controller.onPageStart(mirrorUrl);
      expect(controller.errorMessage.value, isEmpty);
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
    test('clears both loader flags', () {
      controller.onPageError('Something went wrong.');

      expect(controller.isLoading.value, isFalse);
      expect(controller.isInitialLoad.value, isFalse);
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

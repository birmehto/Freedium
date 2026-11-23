import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/constants/app_constants.dart';
import 'package:freedium/core/network/article_resolver.dart';
import 'package:freedium/core/providers/service_providers.dart';
import 'package:freedium/features/article/controllers/article_controller.dart';
import 'package:freedium/features/article/models/article_request.dart';

import '../../helpers/test_env.dart';

/// Covers the reader's loading state machine.
///
/// No WebView is created, so this drives the exact callbacks the WebView
/// reports: `onLoadStart`, `onPageCommitVisible`, progress updates,
/// `onLoadStop` and page errors.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestServices services;
  late ProviderContainer container;
  late ArticleController controller;
  late ArticleResolver resolver;

  const url = 'https://medium.com/@someone/a-story-abc123';
  const mirrorUrl = 'https://freedium-mirror.cfd/proxied-story';

  setUp(() {
    services = registerServices();
    // A child scope keeps the shared services but lets each test own the
    // notifier it drives. ArticleController's onDispose currently calls
    // ref.read inside a disposal callback, which Riverpod reports in debug
    // mode; the handler keeps that library-side assertion from failing tests
    // that only want to dispose their own scope.
    container = ProviderContainer(
      parent: services.container,
      // ignore: invalid_use_of_internal_member
      onError: (_, _) {},
    );
    // Read the resolver the controller gets from the container, so mirror
    // health changes made here are the ones the reader actually sees.
    resolver = container.read(articleResolverProvider);
    controller = container.read(articleControllerProvider.notifier);
  });

  tearDown(() => container.dispose());

  ArticleState state() => container.read(articleControllerProvider);

  /// The fallback title the reader shows while no page has loaded yet.
  String titleFromUrl(ArticleController target, String source) {
    target.debugTitleFromUrl(source);
    return state().articleTitle;
  }

  group('initial state', () {
    test('starts loading, with no progress and no error', () {
      expect(state().isLoading, isTrue);
      expect(state().isInitialLoad, isTrue);
      expect(state().loadingProgress, 0);
      expect(state().errorMessage, isEmpty);
    });
  });

  group('updateProgress', () {
    test('reports progress as a 0..1 fraction', () {
      controller.updateProgress(40);
      expect(state().loadingProgress, closeTo(0.4, 1e-9));

      controller.updateProgress(75);
      expect(state().loadingProgress, closeTo(0.75, 1e-9));
    });

    test('clamps out-of-range and nonsensical values', () {
      controller.updateProgress(140);
      expect(state().loadingProgress, 1.0);

      controller.updateProgress(-20);
      expect(state().loadingProgress, 0.0);
    });

    test('intermediate progress keeps the loader visible', () {
      controller.updateProgress(50);

      expect(state().isLoading, isTrue);
      expect(state().isInitialLoad, isTrue);
    });

    test('stops loading once progress reaches 100', () {
      controller.updateProgress(100);

      expect(state().isLoading, isFalse);
      expect(state().isInitialLoad, isFalse);
      expect(state().loadingProgress, 1.0);
    });

    test('reaches 100 and clears loading even without onLoadStop', () {
      // Regression: the reader kept spinning on articles that had already
      // finished loading whenever onLoadStop was late or skipped.
      controller
        ..onPageStart(mirrorUrl)
        ..updateProgress(100);

      expect(state().isLoading, isFalse);
      expect(state().isInitialLoad, isFalse);
    });

    test('is idempotent when the load already completed', () {
      controller
        ..onPageLoaded()
        ..updateProgress(100);

      expect(state().isLoading, isFalse);
      expect(state().loadingProgress, 1.0);
    });
  });

  group('onPageStart', () {
    test('re-arms the loader for the next page', () {
      controller
        ..onPageLoaded()
        ..onPageStart(mirrorUrl);

      expect(state().isLoading, isTrue);
      expect(state().currentUrl, mirrorUrl);
    });

    test('clears a previous error', () async {
      await controller.onPageError('boom');
      expect(state().errorMessage, isNotEmpty);

      controller.onPageStart(mirrorUrl);
      expect(state().errorMessage, isEmpty);
    });

    test('resets a full progress bar from the previous load', () {
      controller
        ..onPageLoaded()
        ..onPageStart(mirrorUrl);

      // A determinate bar left at 100% reads as "finished" for the whole of the
      // next load.
      expect(state().loadingProgress, 0);
    });

    test('accepts a null URL without clobbering the current one', () {
      controller.onPageStart(mirrorUrl);
      controller.onPageStart(null);

      expect(state().currentUrl, mirrorUrl);
    });
  });

  group('onPageCommitVisible', () {
    test('dismisses the loader once the document is painted', () {
      controller
        ..onPageStart(mirrorUrl)
        ..onPageCommitVisible();

      expect(state().isLoading, isFalse);
      expect(state().isInitialLoad, isFalse);
    });

    test('is a no-op on an already idle controller', () {
      controller
        ..onPageLoaded()
        ..onPageCommitVisible();

      expect(state().isLoading, isFalse);
      expect(state().errorMessage, isEmpty);
    });

    test('a late onLoadStart cannot re-block an already visible page', () {
      controller
        ..onPageLoaded()
        ..onPageStart(mirrorUrl)
        ..onPageCommitVisible();

      expect(state().isLoading, isFalse);
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

      expect(state().isLoading, isFalse);
      expect(state().isInitialLoad, isFalse);
    });

    test(
      'cancels the watchdog, so a finished page is not turned into an error',
      () {
        fakeAsync((async) {
          controller
            ..onPageStart(mirrorUrl)
            ..updateProgress(100);

          async.elapse(AppConstants.webViewTimeout * 3);

          expect(state().errorMessage, isEmpty);
        });
      },
    );

    test('leaves a partial load alone', () {
      controller
        ..onPageStart(mirrorUrl)
        ..updateProgress(40);

      expect(state().isLoading, isTrue);
      expect(state().isInitialLoad, isTrue);
    });
  });

  group('onPageLoaded', () {
    test('completes the load', () {
      controller.onPageLoaded();

      expect(state().isLoading, isFalse);
      expect(state().isInitialLoad, isFalse);
      expect(state().loadingProgress, 1.0);
    });

    test('is safe to call twice', () {
      controller
        ..onPageLoaded()
        ..onPageLoaded();

      expect(state().isLoading, isFalse);
    });
  });

  group('watchdog', () {
    test('a page that never finishes is reported as a timeout', () {
      fakeAsync((async) {
        controller.onPageStart(mirrorUrl);
        expect(state().isLoading, isTrue);

        async.elapse(AppConstants.webViewTimeout + const Duration(seconds: 1));

        // The resolver may have fallen back to another mirror, but either way
        // the reader must not still be showing a permanent loader.
        expect(state().isLoading, isFalse);
      });
    });

    test('a committed page is not replaced by a spurious timeout', () {
      fakeAsync((async) {
        controller
          ..onPageStart(mirrorUrl)
          ..onPageCommitVisible();

        async.elapse(AppConstants.webViewTimeout * 3);

        // Reading a normal article must never turn into a timeout error.
        expect(state().errorMessage, isEmpty);
        expect(state().isLoading, isFalse);
      });
    });

    test('a finished page is not replaced by a spurious timeout', () {
      fakeAsync((async) {
        controller.onPageLoaded();

        async.elapse(AppConstants.webViewTimeout * 3);

        expect(state().errorMessage, isEmpty);
      });
    });

    test('the timeout is long enough to be useful', () {
      expect(AppConstants.webViewTimeout.inSeconds, greaterThanOrEqualTo(15));
    });
  });

  group('onPageError', () {
    test('clears both loader flags', () async {
      await controller.onPageError('Something went wrong.');

      expect(state().isLoading, isFalse);
      expect(state().isInitialLoad, isFalse);
    });

    test(
      'one failure is handled once, however many times it is reported',
      () async {
        // A main-frame request can report both an HTTP error and a transport
        // error. Handling the second one as well retired a second mirror — one
        // that had never served the article — and issued a second load that
        // cancelled the first.
        await controller.onPageError('Connection failed.');
        final failing = state().attemptedMirrors.toList();

        await controller.onPageError('Connection failed.');
        await controller.onPageError('Connection failed.');

        expect(state().attemptedMirrors.toList(), failing);
      },
    );

    test('a later navigation may fail again', () async {
      await controller.onPageError('Connection failed.');
      final failing = state().attemptedMirrors.length;

      controller.onPageStart(mirrorUrl);
      await controller.open(const ArticleRequest(url: url));
      await controller.onPageError('Connection failed.');

      expect(state().attemptedMirrors.length, greaterThanOrEqualTo(failing));
    });

    test(
      'a mirror that failed is not asked again for the same article',
      () async {
        await controller.onPageError('Connection failed.');

        // The reader walks past mirrors it has already tried, but without a
        // fallback left it stops and surfaces the error.
        expect(state().errorMessage, isNotEmpty);
      },
    );
  });

  group('mirror health', () {
    test('a saved copy is not a sign that the mirror worked', () async {
      const offlineUrl = 'https://medium.com/@someone/offline-story';
      await services.storage.cache.save(
        url: offlineUrl,
        html: '<article><p>Cached body.</p></article>',
        title: 'Cached',
      );
      // One place for the failure to land: the saved copy.
      services.storage.preferences.autoFallback = false;

      await controller.open(const ArticleRequest(url: offlineUrl));
      final failed = resolver.sources.first;
      await controller.onPageError('boom');

      expect(state().isOffline, isTrue);
      expect(failed.consecutiveFailures, 1);

      controller.onPageLoaded();

      // Crediting the mirror for a document that came from disk resets the
      // failure count of the mirror that just failed, so the next article picks
      // it again and pays another timeout.
      expect(failed.consecutiveFailures, 1);
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
      expect(titleFromUrl(controller, '$url/'), isNotEmpty);
      expect(titleFromUrl(controller, 'https://medium.com/'), 'Article');
    });
  });

  group('onClose', () {
    test('cancels the watchdog so it cannot fire on a disposed controller', () {
      fakeAsync((async) {
        controller.onPageStart(mirrorUrl);
        final beforeClose = state();

        // Disposing the container is the Riverpod equivalent of closing the
        // controller: it runs the notifier's onDispose and cancels its timer.
        container.dispose();

        async.elapse(AppConstants.webViewTimeout * 2);

        expect(beforeClose.isLoading, isTrue);
      });
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/network/article_url.dart';
import 'package:freedium/core/providers/service_providers.dart';
import 'package:freedium/core/services/clipboard_service.dart';
import 'package:freedium/core/services/share_intent_service.dart';
import 'package:freedium/features/home/controllers/home_controller.dart';

import '../../helpers/test_env.dart';

class FakeClipboardService extends ClipboardService {
  String? clipboardText = 'https://medium.com/@username/article-slug-123';

  @override
  Future<String?> getFromClipboard() async => clipboardText;
}

/// Test seam for seeding a failure message. The production controller only
/// writes that field from its private navigation/error paths.
class TestHomeController extends HomeController {
  void seedError(String message) =>
      state = state.copyWith(errorMessage: message);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeClipboardService clipboard;
  late ShareIntentService shareIntent;
  late ProviderContainer container;
  late TestHomeController controller;

  setUp(() {
    final services = registerServices();
    clipboard = FakeClipboardService();
    shareIntent = services.shareIntent;

    // The fake clipboard is injected through the provider container so the
    // controller reads it exactly as the app does.
    container = ProviderContainer(
      overrides: [
        storageServiceProvider.overrideWithValue(services.storage),
        shareIntentServiceProvider.overrideWithValue(shareIntent),
        clipboardServiceProvider.overrideWithValue(clipboard),
        homeControllerProvider.overrideWith(TestHomeController.new),
      ],
    );
    controller =
        container.read(homeControllerProvider.notifier) as TestHomeController;
  });

  tearDown(() => container.dispose());

  group('HomeController', () {
    test('starts with empty input', () {
      final state = container.read(homeControllerProvider);
      expect(controller.urlController.text, '');
      expect(state.urlText, '');
      expect(state.errorMessage, '');
      expect(state.isLoading, isFalse);
      expect(controller.canOpenArticle, isFalse);
    });

    test('a valid URL enables opening', () {
      controller.urlController.text =
          'https://medium.com/@user/my-awesome-post-abc123';

      expect(
        container.read(homeControllerProvider).urlText,
        contains('my-awesome-post'),
      );
      expect(controller.canOpenArticle, isTrue);
    });

    test('a non-Medium URL cannot be opened', () {
      controller.urlController.text = 'https://google.com';

      expect(controller.canOpenArticle, isFalse);
    });

    test('whitespace alone does not enable opening', () {
      controller.urlController.text = '   ';

      expect(controller.canOpenArticle, isFalse);
    });

    test('editing clears a previous failure message', () {
      controller.seedError('Something went wrong');
      controller.onUrlChanged('https://medium.com/x');

      expect(container.read(homeControllerProvider).errorMessage, '');
    });

    test('pasteFromClipboard fills the field', () async {
      clipboard.clipboardText = 'https://medium.com/stories/nice-read-xyz';

      await controller.pasteFromClipboard();

      expect(controller.urlController.text, clipboard.clipboardText);
      expect(controller.canOpenArticle, isTrue);
    });

    test('pasteFromClipboard ignores an empty clipboard', () async {
      clipboard.clipboardText = '';

      await controller.pasteFromClipboard();

      expect(controller.urlController.text, '');
    });

    test('clearUrl resets the field', () {
      controller.urlController.text = 'https://medium.com/x';
      controller.seedError('stale failure');

      controller.clearUrl();

      final state = container.read(homeControllerProvider);
      expect(controller.urlController.text, '');
      expect(state.errorMessage, '');
      expect(controller.canOpenArticle, isFalse);
    });

    test('a shared URL is picked up and consumed', () {
      shareIntent.incomingUrl.value = 'https://medium.com/@user/shared-post';

      expect(
        controller.urlController.text,
        'https://medium.com/@user/shared-post',
      );
      expect(
        shareIntent.incomingUrl.value,
        isNull,
        reason: 'the pending share should be consumed exactly once',
      );
    });

    test('a shared URL opens even after an earlier failure', () {
      controller.seedError('stale failure');

      shareIntent.incomingUrl.value = 'https://medium.com/@user/shared-post';

      expect(container.read(homeControllerProvider).errorMessage, isEmpty);
      expect(controller.canOpenArticle, isTrue);
    });

    test('a shared non-Medium URL is refused by the field', () {
      shareIntent.incomingUrl.value = 'https://google.com/search?q=medium';

      expect(
        ArticleUrl.validationError(controller.urlController.text),
        'Only Medium links are supported',
      );
      expect(controller.canOpenArticle, isFalse);
    });
  });
}

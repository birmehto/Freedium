import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/services/clipboard_service.dart';
import 'package:freedium/core/services/share_intent_service.dart';
import 'package:freedium/features/home/controllers/home_controller.dart';
import 'package:get/get.dart';

import '../../helpers/test_env.dart';

class FakeClipboardService extends ClipboardService {
  String? clipboardText = 'https://medium.com/@username/article-slug-123';

  @override
  Future<String?> getFromClipboard() async => clipboardText;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeClipboardService clipboard;
  late HomeController controller;

  setUp(() {
    registerServices();
    clipboard = FakeClipboardService();
    Get.put<ClipboardService>(clipboard);
    controller = HomeController(clipboard, Get.find());
    controller.onInit();
  });

  tearDown(() => controller.onClose());

  group('HomeController', () {
    test('starts with empty input', () {
      expect(controller.urlController.text, '');
      expect(controller.urlText.value, '');
      expect(controller.errorMessage.value, '');
      expect(controller.isLoading.value, isFalse);
      expect(controller.canOpenArticle, isFalse);
    });

    test('a valid URL enables opening', () {
      controller.urlController.text =
          'https://medium.com/@user/my-awesome-post-abc123';

      expect(controller.urlText.value, contains('my-awesome-post'));
      expect(controller.canOpenArticle, isTrue);
    });

    test('a non-Medium URL is accepted', () {
      controller.urlController.text = 'https://google.com';

      expect(controller.canOpenArticle, isTrue);
    });

    test('whitespace alone does not enable opening', () {
      controller.urlController.text = '   ';

      expect(controller.canOpenArticle, isFalse);
    });

    test('editing clears a previous failure message', () {
      controller.errorMessage.value = 'Something went wrong';
      controller.onUrlChanged('https://medium.com/x');

      expect(controller.errorMessage.value, '');
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
      controller.errorMessage.value = 'stale failure';

      controller.clearUrl();

      expect(controller.urlController.text, '');
      expect(controller.errorMessage.value, '');
      expect(controller.canOpenArticle, isFalse);
    });

    test('a shared URL is picked up and consumed', () {
      Get.find<ShareIntentService>().incomingUrl.value =
          'https://medium.com/@user/shared-post';

      expect(
        controller.urlController.text,
        'https://medium.com/@user/shared-post',
      );
      expect(
        Get.find<ShareIntentService>().incomingUrl.value,
        isNull,
        reason: 'the pending share should be consumed exactly once',
      );
    });
  });
}

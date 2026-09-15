import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/services/clipboard_service.dart';
import 'package:freedium/features/home/controllers/home_controller.dart';
import 'package:get/get.dart';

class MockClipboardService extends ClipboardService {
  String? clipboardText = 'https://medium.com/@username/article-slug-123';

  @override
  Future<String?> getFromClipboard() async {
    return clipboardText;
  }
}

void main() {
  late MockClipboardService mockClipboard;
  late HomeController controller;

  setUp(() {
    Get.reset();
    mockClipboard = MockClipboardService();
    Get.put<ClipboardService>(mockClipboard);
    controller = HomeController();
    controller.onInit();
  });

  group('HomeController Tests', () {
    test('Initialization should set empty default states', () {
      expect(controller.urlController.text, '');
      expect(controller.urlText.value, '');
      expect(controller.errorMessage.value, '');
      expect(controller.isLoading.value, false);
      expect(controller.canOpenArticle, false);
    });

    test('Valid Medium URL enables opening article', () {
      controller.urlController.text =
          'https://medium.com/@user/my-awesome-post-abc123';

      expect(
        controller.urlText.value,
        'https://medium.com/@user/my-awesome-post-abc123',
      );
      expect(controller.errorMessage.value, '');
      expect(controller.canOpenArticle, true);
    });

    test('Invalid URL sets validation error message', () {
      controller.onUrlChanged('not-a-valid-url');

      expect(controller.errorMessage.value, 'Please enter a valid URL');
      expect(controller.canOpenArticle, false);
    });

    test('Non-Medium URL is accepted', () {
      controller.urlController.text = 'https://google.com';

      expect(controller.errorMessage.value, '');
      expect(controller.canOpenArticle, true);
    });

    test('pasteFromClipboard populates URL from clipboard', () async {
      mockClipboard.clipboardText = 'https://medium.com/stories/nice-read-xyz';

      await controller.pasteFromClipboard();

      expect(
        controller.urlController.text,
        'https://medium.com/stories/nice-read-xyz',
      );
      expect(controller.errorMessage.value, '');
      expect(controller.canOpenArticle, true);
    });

    test('clearUrl resets input and error state', () {
      controller.onUrlChanged('invalid-stuff');
      expect(controller.errorMessage.value.isNotEmpty, true);

      controller.clearUrl();

      expect(controller.urlController.text, '');
      expect(controller.errorMessage.value, '');
    });
  });
}

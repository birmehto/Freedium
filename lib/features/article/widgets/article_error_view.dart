import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/widgets/app_error.dart';
import '../controllers/article_controller.dart';

/// Full-bleed error state shown inside the article stack when loading fails.
class ArticleErrorView extends StatelessWidget {
  const ArticleErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    // Reactive: `errorMessage` is set after the page is built, so reading it
    // outside an `Obx` meant this view never appeared.
    return Obx(() {
      final controller = Get.find<ArticleController>();
      final message = controller.errorMessage.value;

      if (message.isEmpty) return const SizedBox.shrink();

      return Positioned.fill(
        child: Material(
          color: context.colors.surface,
          child: AppError(
            title: 'Failed to Load Article',
            message: message,
            onRetry: controller.requestRefresh,
            secondaryLabel: 'Open in Browser',
            onSecondary: controller.openInBrowser,
            hint: 'Try refreshing or opening the article in your browser.',
          ),
        ),
      );
    });
  }
}

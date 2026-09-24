import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/app_error.dart';
import '../controllers/article_controller.dart';

/// Full-bleed error state shown inside the article stack when loading fails.
class ArticleErrorView extends StatelessWidget {
  const ArticleErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<ArticleController>();

    if (controller.errorMessage.isEmpty) return const SizedBox.shrink();

    return Positioned.fill(
      child: Material(
        color: theme.scaffoldBackgroundColor,
        child: AppError(
          title: 'Failed to Load Article',
          message: controller.errorMessage.value,
          onRetry: controller.requestRefresh,
          secondaryLabel: 'Open in Browser',
          onSecondary: controller.openInBrowser,
          hint: 'Try refreshing or opening the article in your browser.',
        ),
      ),
    );
  }
}

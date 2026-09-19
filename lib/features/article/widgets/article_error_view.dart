import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../core/widgets/app_button.dart';
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
          extraActions: [
            if (controller.savedCopyAvailable.value)
              AppButton(
                variant: AppButtonVariant.tonal,
                onPressed: controller.openSavedCopy,
                isFullWidth: true,
                icon: const Icon(M3EIcons.download_rounded, size: 20),
                label: const Text('Open saved copy'),
              ),
            if (!controller.savedCopyAvailable.value)
              AppButton(
                variant: AppButtonVariant.tonal,
                onPressed: controller.tryNextMirror,
                isFullWidth: true,
                icon: const Icon(M3EIcons.swap_horiz_rounded, size: 20),
                label: const Text('Try another source'),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/app_animations.dart';
import '../../../../shared/widgets/app_page.dart';
import '../controllers/home_controller.dart';
import '../widgets/home_widgets.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppPage(
      title: 'Readora',
      actions: [
        M3EIconButton(
          icon: const Icon(Icons.favorite_rounded),
          onPressed: () => Get.toNamed(AppRoutes.favorites),
        ),
        M3EIconButton(
          icon: const Icon(Icons.settings_rounded),
          onPressed: () => Get.toNamed(AppRoutes.settings),
        ),
        const SizedBox(width: 8),
      ],
      slivers: [
        const SizedBox(height: 30),

        const ScaleIn(
          delay: Duration(milliseconds: 100),
          child: Center(
            child: Hero(tag: 'article_icon', child: HomeHeaderIcon()),
          ),
        ),

        const SizedBox(height: 30),

        FadeSlideIn(
          delay: const Duration(milliseconds: 200),
          child: Text(
            'Read Freely',
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
              height: 1.0,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),

        const SizedBox(height: 16),

        FadeSlideIn(
          delay: const Duration(milliseconds: 300),
          child: Text(
            'Unlock premium Medium content instantly.\nNo limits. No paywalls.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(height: 30),

        FadeSlideIn(
          delay: const Duration(milliseconds: 400),
          child: Obx(() {
            final hasText = controller.urlText.isNotEmpty;

            return M3ETextField(
              controller: controller.urlController,
              label: 'Paste Medium URL here...',
              onChanged: controller.onUrlChanged,
              onSubmitted: (_) => controller.openArticle(),
              errorText: controller.errorMessage.value.isEmpty
                  ? null
                  : controller.errorMessage.value,
              trailing: Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: M3EIconButton(
                  icon: Icon(
                    hasText ? Icons.clear_rounded : Icons.content_paste_rounded,
                    size: 20,
                  ),
                  onPressed: hasText
                      ? controller.clearUrl
                      : controller.pasteFromClipboard,
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 24),

        FadeSlideIn(
          delay: const Duration(milliseconds: 500),
          child: Obx(
            () => M3EButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () {
                      context.unfocus();
                      controller.openArticle();
                    },
              child: controller.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Unlock Article'),
                      ],
                    ),
            ),
          ),
        ),

        const SizedBox(height: 64),
      ],
    );
  }
}

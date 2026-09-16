import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/widgets/app_app_bar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_textform.dart';
import '../controllers/home_controller.dart';
import '../widgets/home_widgets.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AppAppBar(title: 'Freedium'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 20),
          const Center(child: HomeHeaderIcon()),
          const SizedBox(height: 30),
          Text(
            'Read Freely',
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
              height: 1.0,
              color: theme.colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Unlock premium Medium content instantly.\nNo limits. No paywalls.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 30),

          Obx(() {
            final hasText = controller.urlText.isNotEmpty;

            return AppTextForm(
              variant: M3ETextFieldVariant.outlined,
              controller: controller.urlController,
              label: 'Paste Medium URL here...',
              onChanged: controller.onUrlChanged,
              onSubmitted: (_) => controller.openArticle(),
              errorText: controller.errorMessage.value.isEmpty
                  ? null
                  : controller.errorMessage.value,
              trailing: InkWell(
                onTap: hasText
                    ? controller.clearUrl
                    : controller.pasteFromClipboard,
                child: Icon(
                  hasText
                      ? M3EIcons.clear_rounded
                      : M3EIcons.content_paste_rounded,
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          Obx(
            () => AppButton(
              label: const Text('Unlock Article'),
              icon: const Icon(M3EIcons.bolt_rounded, size: 20),
              size: M3EButtonSize.md,
              isLoading: controller.isLoading.value,
              onPressed: () {
                context.unfocus();
                controller.openArticle();
              },
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}

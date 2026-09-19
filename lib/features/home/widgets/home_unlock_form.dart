import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_textform.dart';
import '../controllers/home_controller.dart';

/// The "Paste a URL" field plus the unlock button.
class HomeUnlockForm extends StatelessWidget {
  const HomeUnlockForm({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Obx(() {
      final hasText = controller.urlText.isNotEmpty;

      return Column(
        children: [
          AppTextForm(
            variant: M3ETextFieldVariant.outlined,
            controller: controller.urlController,
            focusNode: controller.urlFocusNode,
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
          ),
          const SizedBox(height: 24),
          AppButton(
            label: const Text('Unlock Article'),
            icon: const Icon(M3EIcons.bolt_rounded, size: 20),
            size: M3EButtonSize.md,
            isLoading: controller.isLoading.value,
            onPressed: () {
              context.unfocus();
              controller.openArticle();
            },
          ),
        ],
      );
    });
  }
}

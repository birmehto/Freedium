import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../core/network/article_url.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_textform.dart';
import '../controllers/home_controller.dart';

class HomeUnlockForm extends GetView<HomeController> {
  const HomeUnlockForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(() {
            final failure = controller.errorMessage.value;

            return AppTextForm(
              controller: controller.urlController,
              focusNode: controller.urlFocusNode,
              label: 'Paste Medium URL here...',
              validator: ArticleUrl.validationError,
              errorText: failure.isEmpty ? null : failure,
              onChanged: controller.onUrlChanged,
              onSubmitted: (_) => controller.submit(),
              trailing: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller.urlController,
                builder: (context, value, _) {
                  final isEmpty = value.text.isEmpty;

                  return IconButton(
                    tooltip: isEmpty ? 'Paste from clipboard' : 'Clear',
                    onPressed: isEmpty
                        ? controller.pasteFromClipboard
                        : controller.clearUrl,
                    icon: Icon(
                      isEmpty
                          ? Icons.content_paste_rounded
                          : Icons.clear_rounded,
                    ),
                  );
                },
              ),
            );
          }),
          const SizedBox(height: AppSpacing.xl),
          Obx(
            () => AppButton(
              label: const Text('Unlock Article'),
              size: M3EButtonSize.md,
              icon: const Icon(Icons.bolt_rounded),
              isFullWidth: true,
              isLoading: controller.isLoading.value,
              onPressed: controller.submit,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/utils/url_validator.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_textform.dart';
import '../controllers/home_controller.dart';

class HomeUnlockForm extends StatelessWidget {
  const HomeUnlockForm({super.key});

  static final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Obx(() {
      final hasText = controller.urlText.isNotEmpty;

      return Form(
        key: _formKey,
        child: Column(
          children: [
            AppTextForm(
              controller: controller.urlController,
              focusNode: controller.urlFocusNode,
              label: 'Paste Medium URL here...',
              onChanged: controller.onUrlChanged,
              onSubmitted: (_) => _submit(context, controller),
              validator: UrlValidator.validateUrl,
              errorText: controller.errorMessage.value.isEmpty
                  ? null
                  : controller.errorMessage.value,
              trailing: IconButton(
                onPressed: hasText
                    ? controller.clearUrl
                    : controller.pasteFromClipboard,
                icon: Icon(
                  hasText ? Icons.clear_rounded : Icons.content_paste_rounded,
                ),
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: const Text('Unlock Article'),
              size: M3EButtonSize.md,
              icon: const Icon(Icons.bolt_rounded),
              isLoading: controller.isLoading.value,
              onPressed: () => _submit(context, controller),
            ),
          ],
        ),
      );
    });
  }

  static void _submit(BuildContext context, HomeController controller) {
    context.unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    controller.openArticle();
  }
}

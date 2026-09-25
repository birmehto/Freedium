import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/network/article_url.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_textform.dart';
import '../controllers/home_controller.dart';

/// URL entry point on Home.
///
/// Stateful so the [Form] key is owned by this widget's element tree instead of
/// being a single static key shared by every instance.
class HomeUnlockForm extends StatefulWidget {
  const HomeUnlockForm({super.key});

  @override
  State<HomeUnlockForm> createState() => _HomeUnlockFormState();
}

class _HomeUnlockFormState extends State<HomeUnlockForm> {
  final _formKey = GlobalKey<FormState>();

  HomeController get _controller => Get.find<HomeController>();

  void _submit() {
    context.unfocus();

    if (_formKey.currentState?.validate() ?? false) {
      _controller.openArticle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(() {
            final failure = _controller.errorMessage.value;

            return AppTextForm(
              controller: _controller.urlController,
              focusNode: _controller.urlFocusNode,
              label: 'Paste Medium URL here...',
              validator: ArticleUrl.validationError,
              errorText: failure.isEmpty ? null : failure,
              onChanged: _controller.onUrlChanged,
              onSubmitted: (_) => _submit(),
              trailing: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller.urlController,
                builder: (context, value, _) => IconButton(
                  tooltip: value.text.isEmpty
                      ? 'Paste from clipboard'
                      : 'Clear',
                  onPressed: value.text.isEmpty
                      ? _controller.pasteFromClipboard
                      : _controller.clearUrl,
                  icon: Icon(
                    value.text.isEmpty
                        ? Icons.content_paste_rounded
                        : Icons.clear_rounded,
                  ),
                ),
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
              isLoading: _controller.isLoading.value,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }
}

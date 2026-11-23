import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/animation/app_animator.dart';
import '../../../core/network/article_url.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/home_controller.dart';

/// A wide URL field with a single bottom rule and a solid ink button.
class HomeUnlockForm extends ConsumerWidget {
  const HomeUnlockForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);
    final ink = AppTheme.ink(context);
    final muted = AppTheme.muted(context);

    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ARTICLE URL',
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: muted, letterSpacing: 1.6),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: ink)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller.urlController,
                    focusNode: controller.urlFocusNode,
                    validator: ArticleUrl.validationError,
                    onChanged: (_) => controller.onUrlChanged(''),
                    onFieldSubmitted: (_) => controller.submit(),
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: ink),
                    decoration: InputDecoration(
                      hintText: 'https://medium.com/…',
                      hintStyle: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(color: muted),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller.urlController,
                  builder: (context, value, _) {
                    final empty = value.text.isEmpty;
                    return IconButton(
                      icon: AppAnimator.switcher(
                        key: empty ? 'paste' : 'clear',
                        child: Icon(
                          empty ? LucideIcons.clipboardPaste : LucideIcons.x,
                          size: 18,
                          color: muted,
                        ),
                      ),
                      tooltip: empty ? 'Paste from clipboard' : 'Clear',
                      onPressed: empty
                          ? controller.pasteFromClipboard
                          : controller.clearUrl,
                    );
                  },
                ),
              ],
            ),
          ),
          if (state.errorMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            AppAnimator.entrance(
              child: Text(
                state.errorMessage,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: state.isLoading ? null : controller.submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: ink,
                foregroundColor: AppTheme.paper(context),
                elevation: 0,
                shape: const RoundedRectangleBorder(),
              ),
              child: state.isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.paper(context),
                      ),
                    )
                  : const Text(
                      'Unlock story',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

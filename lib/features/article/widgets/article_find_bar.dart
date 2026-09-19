import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../controllers/article_controller.dart';

/// Floating find-in-page bar shown while find mode is active.
class ArticleFindBar extends StatelessWidget {
  const ArticleFindBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final controller = Get.find<ArticleController>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 24, 16),
        child: Material(
          color: c.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: c.outlineVariant),
          ),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const Icon(M3EIcons.search_rounded),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    autofocus: true,
                    onChanged: controller.onFindQueryChanged,
                    onSubmitted: (_) => controller.findNext(true),
                    decoration: const InputDecoration(
                      hintText: 'Find in article',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Obx(
                  () => Text(
                    controller.findMatchCount.value > 0
                        ? '${controller.findMatchIndex.value}/${controller.findMatchCount.value}'
                        : '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: c.onSurfaceVariant,
                    ),
                  ),
                ),
                M3EIconButton(
                  icon: const Icon(M3EIcons.keyboard_arrow_up_rounded),
                  tooltip: 'Previous match',
                  onPressed: () => controller.findNext(false),
                ),
                M3EIconButton(
                  icon: const Icon(M3EIcons.keyboard_arrow_down_rounded),
                  tooltip: 'Next match',
                  onPressed: () => controller.findNext(true),
                ),
                M3EIconButton(
                  icon: const Icon(M3EIcons.close_rounded),
                  tooltip: 'Close find',
                  onPressed: controller.closeFind,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

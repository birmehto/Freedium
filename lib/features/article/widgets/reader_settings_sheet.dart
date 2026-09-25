import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_choice_chips.dart';
import '../../../core/widgets/app_slider_row.dart';
import '../../settings/models/reader_settings.dart';
import '../../settings/models/reader_theme_mode.dart';
import '../controllers/article_controller.dart';

void showReaderSettingsSheet(BuildContext context) {
  final controller = Get.find<ArticleController>();

  Get.bottomSheet(
    AppBottomSheet(
      title: 'Reading Settings',
      child: Obx(() {
        final current = controller.readingSettings.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppChoiceChips(
              title: 'Theme',
              labels: ReaderThemeMode.values.map((m) => m.label).toList(),
              selected: current.themeMode.label,
              onSelected: (label) => controller.updateReaderSettings(
                current.copyWith(
                  themeMode: ReaderThemeMode.values.firstWhere(
                    (m) => m.label == label,
                  ),
                ),
              ),
            ),
            AppChoiceChips(
              title: 'Font family',
              labels: const ['System', 'Georgia', 'Inter', 'Merriweather'],
              selected: current.fontFamily,
              onSelected: (label) => controller.updateReaderSettings(
                current.copyWith(fontFamily: label),
              ),
            ),
            AppSliderRow(
              title: 'Font size',
              value: current.fontSize,
              min: ReaderSettings.kMinFontSize,
              max: ReaderSettings.kMaxFontSize,
              divisions:
                  ((ReaderSettings.kMaxFontSize -
                              ReaderSettings.kMinFontSize) ~/
                          ReaderSettings.kFontSizeStep)
                      .toInt(),
              label: '${current.fontSize.toStringAsFixed(0)} px',
              onChanged: (v) => controller.updateReaderSettings(
                current.copyWith(fontSize: v),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () =>
                    controller.updateReaderSettings(const ReaderSettings()),
                child: const Text('Reset defaults'),
              ),
            ),
          ],
        );
      }),
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

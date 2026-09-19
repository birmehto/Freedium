import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_choice_chips.dart';
import '../../../core/widgets/app_slider_row.dart';
import '../controllers/settings_controller.dart';
import '../models/reader_settings.dart';
import '../models/reader_theme_mode.dart';

void showReaderAppearanceSheet(BuildContext context) {
  final controller = Get.find<SettingsController>();

  Get.bottomSheet(
    AppBottomSheet(
      title: 'Reader Appearance',
      child: Obx(() {
        final current = controller.readerSettings.value;
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
              title: 'Line height',
              value: current.lineHeight,
              min: 1.2,
              max: 2.6,
              divisions: 14,
              label: current.lineHeight.toStringAsFixed(1),
              onChanged: (v) => controller.updateReaderSettings(
                current.copyWith(
                  lineHeight: double.parse(v.toStringAsFixed(1)),
                ),
              ),
            ),
            AppSliderRow(
              title: 'Paragraph spacing',
              value: current.paragraphSpacing,
              min: 0.0,
              max: 2.0,
              divisions: 10,
              label: '${current.paragraphSpacing.toStringAsFixed(1)} em',
              onChanged: (v) => controller.updateReaderSettings(
                current.copyWith(
                  paragraphSpacing: double.parse(v.toStringAsFixed(1)),
                ),
              ),
            ),
            AppSliderRow(
              title: 'Content width',
              value: current.contentWidthEm,
              min: 30,
              max: 54,
              divisions: 24,
              label: '${current.contentWidthEm.toStringAsFixed(0)} em',
              onChanged: (v) => controller.updateReaderSettings(
                current.copyWith(contentWidthEm: v),
              ),
            ),
            AppChoiceChips(
              title: 'Text alignment',
              labels: const ['Left', 'Justify', 'Center'],
              selected: current.textAlign,
              onSelected: (label) => controller.updateReaderSettings(
                current.copyWith(
                  textAlign: label == 'Justify'
                      ? 'justify'
                      : label.toLowerCase(),
                ),
              ),
            ),
            const SizedBox(height: 8),
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

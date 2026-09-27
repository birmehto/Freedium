import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_choice_chips.dart';
import '../../../core/widgets/app_slider_row.dart';
import '../models/reader_settings.dart';
import '../models/reader_theme_mode.dart';

/// Opens the reader-appearance editor.
///
/// One sheet for both Settings and the reader, so the two cannot offer
/// different options or drift out of sync. The caller supplies the state and how
/// to change it, because the reader edits its own copy while Settings edits the
/// stored default.
void showReaderAppearanceSheet(
  BuildContext context, {
  required Rx<ReaderSettings> settings,
  required ValueChanged<ReaderSettings> onChanged,
}) {
  Get.bottomSheet(
    AppBottomSheet(
      title: 'Reader Appearance',
      child: Obx(() {
        final current = settings.value;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppChoiceChips(
              title: 'Theme',
              labels: ReaderThemeMode.values.map((m) => m.label).toList(),
              selected: current.themeMode.label,
              onSelected: (label) => onChanged(
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
              onSelected: (label) =>
                  onChanged(current.copyWith(fontFamily: label)),
            ),
            AppSliderRow(
              title: 'Font size',
              value: current.fontSize,
              min: ReaderSettings.kMinFontSize,
              max: ReaderSettings.kMaxFontSize,
              divisions: ReaderSettings.kFontSizeDivisions,
              label: '${current.fontSize.toStringAsFixed(0)} px',
              onChanged: (size) => onChanged(current.copyWith(fontSize: size)),
            ),

            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => onChanged(const ReaderSettings()),
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

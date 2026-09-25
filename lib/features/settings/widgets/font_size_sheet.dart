import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../controllers/settings_controller.dart';
import '../models/reader_settings.dart';

void showFontSizeSheet(BuildContext context) {
  final controller = Get.find<SettingsController>();

  Get.bottomSheet(
    AppBottomSheet(
      title: 'Default Font Size',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Decrease font size',
                onPressed: () => _adjustSize(-ReaderSettings.kFontSizeStep),
                icon: const Icon(M3EIcons.remove_rounded),
              ),
              Expanded(
                child: Obx(
                  () => M3ESlider(
                    value: controller.fontSize,
                    min: ReaderSettings.kMinFontSize,
                    max: ReaderSettings.kMaxFontSize,
                    divisions:
                        ((ReaderSettings.kMaxFontSize -
                                    ReaderSettings.kMinFontSize) ~/
                                ReaderSettings.kFontSizeStep)
                            .toInt(),
                    label: controller.fontSize.toStringAsFixed(0),
                    onChanged: controller.setFontSize,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Increase font size',
                onPressed: () => _adjustSize(ReaderSettings.kFontSizeStep),
                icon: const Icon(M3EIcons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () =>
                  controller.setFontSize(ReaderSettings.kDefaultFontSize),
              child: const Text('Reset to default'),
            ),
          ),
        ],
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

void _adjustSize(double delta) {
  final controller = Get.find<SettingsController>();
  final next = controller.fontSize + delta;
  if (next >= ReaderSettings.kMinFontSize &&
      next <= ReaderSettings.kMaxFontSize) {
    controller.setFontSize(next);
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../controllers/settings_controller.dart';

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
                onPressed: () => _adjustSize(-AppConstants.fontSizeStep),
                icon: const Icon(M3EIcons.remove_rounded),
              ),
              Expanded(
                child: Obx(
                  () => M3ESlider(
                    value: controller.fontSize.value,
                    min: AppConstants.minFontSize,
                    max: AppConstants.maxFontSize,
                    divisions:
                        ((AppConstants.maxFontSize -
                                    AppConstants.minFontSize) ~/
                                AppConstants.fontSizeStep)
                            .toInt(),
                    label: controller.fontSize.value.toStringAsFixed(0),
                    onChanged: controller.setFontSize,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Increase font size',
                onPressed: () => _adjustSize(AppConstants.fontSizeStep),
                icon: const Icon(M3EIcons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () =>
                  controller.setFontSize(AppConstants.defaultFontSize),
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
  final next = controller.fontSize.value + delta;
  if (next >= AppConstants.minFontSize && next <= AppConstants.maxFontSize) {
    controller.setFontSize(next);
  }
}

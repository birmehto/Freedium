import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../controllers/article_controller.dart';

class ReadingSettingsSheet extends GetView<ArticleController> {
  const ReadingSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reading Settings', style: theme.textTheme.titleLarge),
          const SizedBox(height: 20),

          Obx(
            () => M3EListItem(
              headline: 'Dark Mode',
              leading: Icon(
                controller.isDarkMode
                    ? M3EIcons.dark_mode
                    : M3EIcons.light_mode,
              ),
              trailing: M3ESwitch(
                value: controller.isDarkMode,
                onChanged: (_) => controller.toggleDarkMode(),
              ),
            ),
          ),
          const M3EDivider(),
          const SizedBox(height: 8),

          Text('Font Size', style: theme.textTheme.titleMedium),
          Obx(
            () => M3ESlider(
              value: controller.fontSize.value,
              min: 14,
              max: 28,
              divisions: 14,
              onChanged: controller.updateFontSize,
            ),
          ),

          const SizedBox(height: 16),
          Text('Font Family', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFontChip(context, 'Inter'),
                _buildFontChip(context, 'Roboto'),
                _buildFontChip(context, 'Merriweather'),
                _buildFontChip(context, 'Open Sans'),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFontChip(BuildContext context, String font) {
    final isSelected = controller.fontFamily.value == font;
    return M3EChip(
      label: font,
      type: M3EChipType.filter,
      selected: isSelected,
      onPressed: () => controller.updateFontFamily(font),
    );
  }
}

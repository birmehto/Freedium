import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../core/constants/reader_theme.dart';
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
  final systemDark = Theme.of(context).brightness == Brightness.dark;

  Get.bottomSheet(
    AppBottomSheet(
      title: 'Reader Appearance',
      child: Obx(() {
        final current = settings.value;

        return _ReaderAppearanceSheet(
          settings: current,
          systemDark: systemDark,
          onChanged: onChanged,
        );
      }),
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

/// The appearance editor's body: a live preview of the current settings,
/// followed by the theme, font-family and font-size controls.
class _ReaderAppearanceSheet extends StatelessWidget {
  const _ReaderAppearanceSheet({
    required this.settings,
    required this.systemDark,
    required this.onChanged,
  });

  final ReaderSettings settings;
  final bool systemDark;
  final ValueChanged<ReaderSettings> onChanged;

  bool get _isDefault =>
      settings.themeMode == ReaderThemeMode.system &&
      settings.fontFamily == ReaderSettings.kDefaultFontFamily &&
      settings.fontSize == ReaderSettings.kDefaultFontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReaderPreview(settings: settings, systemDark: systemDark),
        const SizedBox(height: AppSpacing.xl),
        AppChoiceChips(
          title: 'Theme',
          labels: ReaderThemeMode.values.map((m) => m.label).toList(),
          selected: settings.themeMode.label,
          labelBuilder: (context, label) => _ThemeChipLabel(
            mode: ReaderThemeMode.values.firstWhere((m) => m.label == label),
            systemDark: systemDark,
          ),
          onSelected: (label) => onChanged(
            settings.copyWith(
              themeMode: ReaderThemeMode.values.firstWhere(
                (m) => m.label == label,
              ),
            ),
          ),
        ),
        AppChoiceChips(
          title: 'Font family',
          labels: const ['System', 'Georgia', 'Inter', 'Merriweather'],
          selected: settings.fontFamily,
          onSelected: (label) =>
              onChanged(settings.copyWith(fontFamily: label)),
        ),
        AppSliderRow(
          title: 'Font size',
          value: settings.fontSize,
          min: ReaderSettings.kMinFontSize,
          max: ReaderSettings.kMaxFontSize,
          divisions: ReaderSettings.kFontSizeDivisions,
          label: '${settings.fontSize.toStringAsFixed(0)} px',
          leading: Text('A', style: theme.textTheme.bodySmall),
          trailing: Text('A', style: theme.textTheme.headlineSmall),
          onChanged: (size) => onChanged(settings.copyWith(fontSize: size)),
        ),

        const SizedBox(height: AppSpacing.lg),
        const Divider(height: 1),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            // Nothing to restore until the user has moved away from defaults,
            // and a disabled button reads better than a no-op tap.
            onPressed: _isDefault
                ? null
                : () => onChanged(const ReaderSettings()),
            icon: const Icon(M3EIcons.restart_alt_rounded, size: 18),
            label: const Text('Reset defaults'),
          ),
        ),
      ],
    );
  }
}

/// A miniature of the reader, painted with the exact palette, family and size
/// the current settings resolve to, so every change is visible before it is
/// committed anywhere.
class _ReaderPreview extends StatelessWidget {
  const _ReaderPreview({required this.settings, required this.systemDark});

  final ReaderSettings settings;
  final bool systemDark;

  @override
  Widget build(BuildContext context) {
    final preview = ReaderTheme.previewColors(settings, systemDark: systemDark);
    final text = _parseHex(preview.text);
    final secondary = _parseHex(preview.secondaryText);
    final link = _parseHex(preview.link);
    final fontFamily = settings.isSystemFont ? null : settings.fontFamily;
    final size = settings.fontSize;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: _parseHex(preview.background),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: text.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aa',
                style: TextStyle(
                  color: text,
                  fontFamily: fontFamily,
                  fontSize: size * 1.5,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: text.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  _resolvedModeLabel,
                  style: TextStyle(
                    color: text,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'The shape of readable text',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: text,
              fontFamily: fontFamily,
              fontSize: size,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Good reading keeps its rhythm in any light \u2014 '
            'a comfortable line, the same words, a calmer surface.',
            style: TextStyle(
              color: secondary,
              fontFamily: fontFamily,
              fontSize: size,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                'Read the full story',
                style: TextStyle(
                  color: link,
                  fontFamily: fontFamily,
                  fontSize: size * 0.9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Icon(M3EIcons.arrow_forward_rounded, size: 16, color: link),
            ],
          ),
        ],
      ),
    );
  }

  /// The palette that is actually in use, resolving `System` against the
  /// platform so the badge names the colors it is showing.
  String get _resolvedModeLabel => switch (settings.themeMode) {
    ReaderThemeMode.system => systemDark ? 'Dark' : 'Light',
    ReaderThemeMode.light => 'Light',
    ReaderThemeMode.dark => 'Dark',
    ReaderThemeMode.sepia => 'Sepia',
    ReaderThemeMode.oled => 'OLED',
  };
}

/// A theme chip label carrying a swatch of the palette it selects.
class _ThemeChipLabel extends StatelessWidget {
  const _ThemeChipLabel({required this.mode, required this.systemDark});

  final ReaderThemeMode mode;
  final bool systemDark;

  @override
  Widget build(BuildContext context) {
    final preview = ReaderTheme.previewColors(
      ReaderSettings(themeMode: mode),
      systemDark: systemDark,
    );
    final background = _parseHex(preview.background);
    final text = _parseHex(preview.text);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: text.withValues(alpha: 0.28)),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(mode.label),
      ],
    );
  }
}

/// Parses the reader palette's `#rrggbb` strings into a [Color].
Color _parseHex(String hex) {
  final value = int.parse(hex.replaceFirst('#', ''), radix: 16);
  return Color(0xFF000000 | value);
}

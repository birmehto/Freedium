import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/animation/app_animator.dart';
import '../../../core/constants/reader_theme.dart';
import '../../../core/controllers/app_controllers.dart';
import '../../../core/theme/app_theme.dart';
import '../models/reader_settings.dart';
import '../models/reader_theme_mode.dart';

/// Opens the one appearance editor shared by Settings and the reader.
///
/// The sheet watches and writes [readerSettingsProvider] itself, so callers do
/// not have to thread state or callbacks through the route.
Future<T?> showReaderAppearanceSheet<T>(BuildContext context) {
  final systemDark = Theme.of(context).brightness == Brightness.dark;

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.paper(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ReaderAppearanceSheet(systemDark: systemDark),
  );
}

class _ReaderAppearanceSheet extends ConsumerWidget {
  const _ReaderAppearanceSheet({required this.systemDark});

  final bool systemDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(readerSettingsProvider);
    final controller = ref.read(readerSettingsProvider.notifier);
    final ink = AppTheme.ink(context);
    final muted = AppTheme.muted(context);
    final rule = AppTheme.rule(context);

    final isDefault =
        settings.themeMode == ReaderThemeMode.system &&
        settings.fontFamily == ReaderSettings.kDefaultFontFamily &&
        settings.fontSize == ReaderSettings.kDefaultFontSize;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SizedBox(
              width: 36,
              height: 4,
              child: ColoredBox(color: rule),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Reader Appearance',
            style: GoogleFonts.sourceSerif4(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: ink,
            ),
          ),
          const SizedBox(height: 20),

          // A miniature of the reader, repainted from the same palette the
          // stylesheet uses, so every change is visible before it is applied.
          AppAnimator.switcher(
            // Font size is applied live; only theme and family swap the preview.
            key: Object.hash(settings.themeMode, settings.fontFamily),
            child: _ReaderPreview(settings: settings, systemDark: systemDark),
          ),

          const SizedBox(height: 28),
          _ChoiceGroup(
            title: 'Theme',
            children: [
              for (final mode in ReaderThemeMode.values)
                _Choice(
                  label: mode.label,
                  selected: settings.themeMode == mode,
                  leading: _ThemeSwatch(
                    mode: mode,
                    systemDark: systemDark,
                  ),
                  onTap: () => controller.update(
                    settings.copyWith(themeMode: mode),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),
          _ChoiceGroup(
            title: 'Font family',
            children: [
              for (final family in const [
                'System',
                'Georgia',
                'Inter',
                'Merriweather',
              ])
                _Choice(
                  label: family,
                  selected: settings.fontFamily == family,
                  onTap: () =>
                      controller.update(settings.copyWith(fontFamily: family)),
                ),
            ],
          ),

          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'FONT SIZE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: muted,
                          letterSpacing: 1.6,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '${settings.fontSize.toStringAsFixed(0)} px',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: ink,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'A',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                  ),
                  Expanded(
                    child: Slider(
                      value: settings.fontSize,
                      min: ReaderSettings.kMinFontSize,
                      max: ReaderSettings.kMaxFontSize,
                      divisions: ReaderSettings.kFontSizeDivisions,
                      onChanged: (size) => controller.update(
                        settings.copyWith(fontSize: size),
                      ),
                    ),
                  ),
                  Text(
                    'A',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: ink,
                        ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),
          Divider(height: 1, color: rule),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: isDefault
                  ? null
                  : () => controller.update(const ReaderSettings()),
              icon: const Icon(LucideIcons.rotateCcw, size: 18),
              label: const Text('Reset defaults'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceGroup extends StatelessWidget {
  const _ChoiceGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.muted(context),
                letterSpacing: 1.6,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final ink = AppTheme.ink(context);
    final muted = AppTheme.muted(context);
    final rule = AppTheme.rule(context);

    return InkResponse(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? ink : rule),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 8)],
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? ink : muted,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A live miniature of the reader, painted from exactly the colors the
/// stylesheet applies.
class _ReaderPreview extends StatelessWidget {
  const _ReaderPreview({required this.settings, required this.systemDark});

  final ReaderSettings settings;
  final bool systemDark;

  @override
  Widget build(BuildContext context) {
    final preview = ReaderTheme.previewColors(
      settings,
      systemDark: systemDark,
    );
    final text = ReaderTheme.hexToColor(preview.text);
    final secondary = ReaderTheme.hexToColor(preview.secondaryText);
    final link = ReaderTheme.hexToColor(preview.link);
    final fontFamily = settings.isSystemFont ? null : settings.fontFamily;
    final size = settings.fontSize;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ReaderTheme.hexToColor(preview.background),
          borderRadius: BorderRadius.circular(14),
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
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: text.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
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
            const SizedBox(height: 16),
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
            const SizedBox(height: 8),
            Text(
              'Good reading keeps its rhythm in any light — '
              'a comfortable line, the same words, a calmer surface.',
              style: TextStyle(
                color: secondary,
                fontFamily: fontFamily,
                fontSize: size,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
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
                const SizedBox(width: 4),
                Icon(LucideIcons.arrowRight, size: 16, color: link),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String get _resolvedModeLabel => switch (settings.themeMode) {
        ReaderThemeMode.system => systemDark ? 'Dark' : 'Light',
        ReaderThemeMode.light => 'Light',
        ReaderThemeMode.dark => 'Dark',
        ReaderThemeMode.sepia => 'Sepia',
        ReaderThemeMode.oled => 'OLED',
      };
}

/// A swatch of the palette a theme chip selects.
class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.mode, required this.systemDark});

  final ReaderThemeMode mode;
  final bool systemDark;

  @override
  Widget build(BuildContext context) {
    final preview = ReaderTheme.previewColors(
      ReaderSettings(themeMode: mode),
      systemDark: systemDark,
    );
    final background = ReaderTheme.hexToColor(preview.background);
    final text = ReaderTheme.hexToColor(preview.text);

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: text.withValues(alpha: 0.28)),
      ),
    );
  }
}

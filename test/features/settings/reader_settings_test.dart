import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/features/settings/models/reader_settings.dart';
import 'package:freedium/features/settings/models/reader_theme_mode.dart';

void main() {
  group('ReaderSettings', () {
    test('defaults match the reader defaults', () {
      const s = ReaderSettings();
      expect(s.fontSize, ReaderSettings.kDefaultFontSize);
      expect(s.fontFamily, ReaderSettings.kDefaultFontFamily);

      expect(s.themeMode, ReaderThemeMode.system);
    });

    test('toJson/fromJson round-trip preserves all fields', () {
      const s = ReaderSettings(
        fontSize: 20,
        fontFamily: 'Georgia',

        themeMode: ReaderThemeMode.sepia,
      );

      final restored = ReaderSettings.fromJson(s.toJson());
      expect(restored.fontSize, s.fontSize);
      expect(restored.fontFamily, s.fontFamily);
      expect(restored.themeMode, s.themeMode);
    });

    test('fromJson falls back to defaults for missing data', () {
      final s = ReaderSettings.fromJson(const {'fontSize': 13.0});
      expect(s.fontSize, 13.0);
      expect(s.fontFamily, ReaderSettings.kDefaultFontFamily);
    });

    test('a stored font size outside the supported range is clamped', () {
      // Out-of-range data used to reach the slider and the reader's stylesheet
      // as-is, pinning the thumb at one end.
      expect(
        ReaderSettings.fromJson(const {'fontSize': 900.0}).fontSize,
        ReaderSettings.kMaxFontSize,
      );
      expect(
        ReaderSettings.fromJson(const {'fontSize': 1.0}).fontSize,
        ReaderSettings.kMinFontSize,
      );
    });

    test('values of the wrong type fall back to the defaults', () {
      final s = ReaderSettings.fromJson(const {
        'fontSize': 'huge',
        'fontFamily': 42,
        'themeMode': 7,
      });

      expect(s.fontSize, ReaderSettings.kDefaultFontSize);
      expect(s.fontFamily, ReaderSettings.kDefaultFontFamily);
      expect(s.themeMode, ReaderThemeMode.system);
    });

    test('isSystemFont identifies the default family', () {
      const s = ReaderSettings();
      expect(s.isSystemFont, isTrue);
      expect(const ReaderSettings(fontFamily: 'Inter').isSystemFont, isFalse);
    });

    test('copyWith replaces only provided fields', () {
      const s = ReaderSettings(fontSize: 14);
      expect(s.copyWith(fontFamily: 'Merriweather').fontSize, 14);
      expect(s.copyWith(fontSize: 24).fontSize, 24);
      expect(s.copyWith(fontFamily: 'Merriweather').fontFamily, 'Merriweather');
    });
  });

  group('ReaderThemeMode', () {
    test('labels and names cover the five reader themes', () {
      expect(ReaderThemeMode.values.map((m) => m.name).toSet(), {
        'system',
        'light',
        'dark',
        'sepia',
        'oled',
      });
      expect(ReaderThemeMode.values, hasLength(5));
    });

    test('fromName round-trips', () {
      for (final mode in ReaderThemeMode.values) {
        expect(ReaderThemeMode.fromName(mode.name), mode);
      }
      expect(ReaderThemeMode.fromName('nope'), ReaderThemeMode.system);
    });
  });
}

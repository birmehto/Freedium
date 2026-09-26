import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/constants/reader_theme.dart';
import 'package:freedium/features/settings/models/reader_settings.dart';
import 'package:freedium/features/settings/models/reader_theme_mode.dart';

String _css({
  ReaderThemeMode mode = ReaderThemeMode.system,
  String fontFamily = 'System',
  double fontSize = 17,
  bool systemDark = false,
}) {
  return ReaderTheme.getCss(
    settings: ReaderSettings(
      themeMode: mode,
      fontFamily: fontFamily,
      fontSize: fontSize,
    ),
    systemDark: systemDark,
  );
}

void main() {
  group('getCss', () {
    test('emits a non-empty stylesheet for every theme', () {
      for (final mode in ReaderThemeMode.values) {
        for (final systemDark in [false, true]) {
          final css = _css(mode: mode, systemDark: systemDark);
          expect(css, isNotEmpty, reason: 'empty CSS for $mode/$systemDark');
          expect(css, contains('color-scheme:'));
        }
      }
    });

    test('System font emits no font-family override', () {
      expect(_css(), isNot(contains('font-family:')));
    });

    test('a named font is quoted and followed by a fallback stack', () {
      final css = _css(fontFamily: 'Georgia');
      expect(css, contains('font-family: "Georgia"'));
      expect(css, contains('system-ui'));
    });

    test('font size is applied in px', () {
      expect(_css(fontSize: 22), contains('font-size: 22.0px'));
    });

    test('font size is clamped to the supported range', () {
      expect(_css(fontSize: 900), contains('font-size: 28.0px'));
      expect(_css(fontSize: 1), contains('font-size: 12.0px'));
    });

    test('a dark theme uses a dark color scheme and vice versa', () {
      expect(_css(mode: ReaderThemeMode.dark), contains('color-scheme: dark'));
      expect(
        _css(mode: ReaderThemeMode.light),
        contains('color-scheme: light'),
      );
      expect(
        _css(mode: ReaderThemeMode.sepia),
        contains('color-scheme: light'),
      );
    });

    test('system theme follows the platform brightness', () {
      expect(_css(systemDark: true), contains('color-scheme: dark'));
      expect(_css(), contains('color-scheme: light'));
    });

    test('every theme reaches a distinct background color', () {
      final backgrounds = ReaderThemeMode.values
          .map((m) => _css(mode: m))
          .toSet();

      // system resolves to light, so five modes collapse to four palettes.
      expect(backgrounds.length, 4);
    });
  });

  group('font family sanitization', () {
    test('rejects a value that tries to close the declaration', () {
      final css = _css(fontFamily: 'Georgia"; } body { display: none } .x{');

      expect(css, isNot(contains('font-family:')));
      // The payload tried to close the declaration and open a new rule.
      expect(css, isNot(contains('Georgia"')));
      expect(css, isNot(contains('.x{')));
    });

    test('rejects rather than partially repairing a hostile value', () {
      // Repairing would yield a bogus family name such as "Merriweatherscript"
      // and hide the fact that the stored preference was corrupt.
      final css = _css(fontFamily: 'Merriweather"><script>');

      expect(css, isNot(contains('font-family:')));
      expect(css, isNot(contains('<script>')));
    });

    test('falls back to the system font when nothing usable remains', () {
      expect(_css(fontFamily: ';;;;'), isNot(contains('font-family:')));
      expect(_css(fontFamily: '   '), isNot(contains('font-family:')));
      expect(_css(fontFamily: ''), isNot(contains('font-family:')));
    });

    test('accepts the family names the settings sheet offers', () {
      for (final family in ['Georgia', 'Inter', 'Merriweather']) {
        expect(_css(fontFamily: family), contains('font-family: "$family"'));
      }
    });

    test('drops an absurdly long family name', () {
      expect(_css(fontFamily: 'A' * 500), isNot(contains('font-family:')));
    });
  });

  group('injectCssScript', () {
    test('embeds the stylesheet as a JSON string, not raw text', () {
      final script = ReaderTheme.injectCssScript('body { color: red }');

      expect(script, contains('style.textContent = "body { color: red }";'));
      expect(script, contains(ReaderTheme.customCssId));
    });

    test('a stylesheet cannot break out of the script string', () {
      const hostile = 'body { color: red }"; alert(1); var x = "';
      final script = ReaderTheme.injectCssScript(hostile);

      // The payload must survive encoding as a JavaScript string literal and
      // decode back to exactly the original stylesheet.
      final literal = RegExp(r'style\.textContent = (.*);')
          .firstMatch(script)!
          .group(1)!;

      expect(jsonDecode(literal), hostile);
    });

    test('removes the early flash-prevention stylesheet', () {
      // Otherwise the document keeps two full copies of the stylesheet alive
      // for the whole session.
      expect(ReaderTheme.injectCssScript('a{}'), contains('early-flash'));
    });

    test('replaces any previous injected stylesheet', () {
      final script = ReaderTheme.injectCssScript('a{}');
      expect(script, contains('custom-reader-style'));
      expect(script, contains('previous.remove()'));
    });
  });

  group('earlyStyleInjector', () {
    test('carries the same stylesheet as the regular injector', () {
      const settings = ReaderSettings();
      final early = ReaderTheme.earlyStyleInjector(
        settings: settings,
        systemDark: false,
      );

      expect(early, contains('freedium-early-flash-prevention'));
      expect(early, contains('color-scheme: light'));
    });
  });

  group('host mode sync', () {
    late String early;
    late String injected;

    setUp(() {
      early = ReaderTheme.earlyStyleInjector(
        settings: const ReaderSettings(),
        systemDark: false,
      );
      injected = ReaderTheme.injectCssScript(_css());
    });

    test('both injectors carry the sync script', () {
      expect(early, contains(ReaderTheme.hostModeSyncJs));
      expect(injected, contains(ReaderTheme.hostModeSyncJs));
    });

    test('runs only after the stylesheet is in the document', () {
      // The script reads `color-scheme` to learn the reader's mode. Running
      // first would leave it falling back to the platform brightness and
      // override an explicitly chosen light or sepia theme.
      for (final script in [early, injected]) {
        expect(
          script.indexOf(ReaderTheme.hostModeSyncJs),
          greaterThan(script.lastIndexOf('appendChild(style)')),
        );
      }
    });

    test('takes the mode from the stylesheet instead of a baked-in value', () {
      // One script serves every theme, so it must not carry a palette of its
      // own or the next theme to ship would need a new one.
      for (final color in ['#1b1915', '#000000', '#f4ecd8', '#fbfaf7']) {
        expect(ReaderTheme.hostModeSyncJs, isNot(contains(color)));
      }

      expect(
        ReaderTheme.hostModeSyncJs,
        contains('getComputedStyle(document.documentElement).colorScheme'),
      );
    });

    test('claims the switches sites gate a dark palette behind', () {
      expect(ReaderTheme.hostModeSyncJs, contains("['dark', 'dark-mode']"));
      expect(
        ReaderTheme.hostModeSyncJs,
        contains("['data-theme', 'data-color-mode']"),
      );
    });

    test('repairs code colors rather than flattening the highlighting', () {
      const script = ReaderTheme.hostModeSyncJs;

      // A blanket override would also nuke palettes that already read.
      expect(script, contains('if (keep >= MIN_CONTRAST || replace <= keep)'));
      expect(script, isNot(contains('pre span')));
    });

    test('installs its observers once per document', () {
      // The stylesheet is re-injected on every settings change.
      expect(ReaderTheme.hostModeSyncJs, contains('window[INSTALLED]'));
    });

    test('restores its own overrides before re-measuring', () {
      // Otherwise a theme change would compare the previous repair against the
      // new palette and keep a color the host no longer asks for.
      const script = ReaderTheme.hostModeSyncJs;
      expect(script, contains('function restore()'));
      expect(
        script.indexOf('restore();'),
        lessThan(script.indexOf('var pending')),
      );
    });
  });

  group('readerIsDark', () {
    test('explicit themes ignore the platform brightness', () {
      for (final systemDark in [false, true]) {
        expect(
          ReaderTheme.readerIsDark(
            const ReaderSettings(themeMode: ReaderThemeMode.light),
            systemDark: systemDark,
          ),
          isFalse,
        );
        expect(
          ReaderTheme.readerIsDark(
            const ReaderSettings(themeMode: ReaderThemeMode.dark),
            systemDark: systemDark,
          ),
          isTrue,
        );
        expect(
          ReaderTheme.readerIsDark(
            const ReaderSettings(themeMode: ReaderThemeMode.oled),
            systemDark: systemDark,
          ),
          isTrue,
        );
        expect(
          ReaderTheme.readerIsDark(
            const ReaderSettings(themeMode: ReaderThemeMode.sepia),
            systemDark: systemDark,
          ),
          isFalse,
        );
      }
    });

    test('system theme follows the platform brightness', () {
      const system = ReaderSettings();
      expect(ReaderTheme.readerIsDark(system, systemDark: true), isTrue);
      expect(ReaderTheme.readerIsDark(system, systemDark: false), isFalse);
    });
  });
}

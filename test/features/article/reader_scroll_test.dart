import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/constants/reader_theme.dart';
import 'package:freedium/features/settings/models/reader_settings.dart';

/// The reader loads the publisher's real page, whose shell pins `html`/`body`
/// to the height of the viewport and hides the overflow, then scrolls an inner
/// container. A document pinned to the viewport is exactly one screen tall, so
/// there is nothing for a drag to move: the article is there and the page will
/// not scroll. These tests hold the stylesheet to that fix, and the measurement
/// scripts to working either way.
void main() {
  group('getCss scrollability', () {
    late String css;

    setUp(
      () => css = ReaderTheme.getCss(
        settings: const ReaderSettings(),
        systemDark: false,
      ),
    );

    /// The declarations for one selector, with comments and `!important`
    /// normalized away.
    List<String> declarationsOf(String selector) {
      final pattern = RegExp(RegExp.escape(selector) + r'\s*\{([^}]*)\}');
      final match = pattern.firstMatch(css);
      if (match == null) return const [];

      return match
          .group(1)!
          .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), ' ')
          .replaceAll('!important', '')
          .split(';')
          .map((declaration) => declaration.trim())
          .where((declaration) => declaration.isNotEmpty)
          .toList();
    }

    test('the root is not pinned to the viewport', () {
      expect(
        declarationsOf('html'),
        contains('height: auto'),
        reason: 'a pinned root is one screen tall and cannot scroll',
      );
      expect(declarationsOf('html'), contains('overflow: visible'));
    });

    test('the body is not pinned to the viewport either', () {
      expect(declarationsOf('body'), contains('height: auto'));
      expect(declarationsOf('body'), contains('max-height: none'));
      expect(declarationsOf('body'), contains('overflow: visible'));
    });

    test('the body is not positioned out of the document flow', () {
      expect(
        declarationsOf('body'),
        contains('position: static'),
        reason: 'a fixed body scrolls behind a viewport-sized frame instead',
      );
    });

    test('the article grows with its content', () {
      expect(declarationsOf('article'), contains('height: auto'));
      expect(declarationsOf('article'), contains('max-height: none'));
      expect(declarationsOf('article'), contains('overflow: visible'));
    });

    test('a pinned wrapper inside the article is released', () {
      // Scoped to the article on purpose: resetting every descendant would
      // flatten the code blocks and figures the reader wants as they are.
      expect(
        css,
        contains('article div[style*="100vh"]'),
        reason: 'the host shell pins its scroll container, not the root',
      );
      expect(css, contains('article main[style*="100vh"]'));
    });

    test('no declaration reintroduces overscroll on the root', () {
      // Overscroll and scroll are different axes: the reader wants the glow
      // gone, and the page still has to move.
      expect(declarationsOf('html'), isNot(contains('overflow: hidden')));
      expect(declarationsOf('body'), isNot(contains('overflow: hidden')));
    });
  });

  group('scrollDiagnosticsJs', () {
    test('reports the geometry a scroll failure turns on', () {
      const js = ReaderTheme.scrollDiagnosticsJs;

      expect(js, contains('contentTallerThanViewport'));
      expect(js, contains('scrollHeight'));
      expect(js, contains('clientHeight'));
      expect(js, contains('innerHeight'));
      expect(js, contains('overflowY'));
      expect(js, contains('getComputedStyle'));
    });

    test('names an inner scroller when the document is not the scroller', () {
      expect(ReaderTheme.scrollDiagnosticsJs, contains('scroller'));
      expect(ReaderTheme.scrollDiagnosticsJs, contains('tagName'));
    });

    test('reports its own failure rather than throwing into the channel', () {
      expect(ReaderTheme.scrollDiagnosticsJs, contains('catch'));
      expect(ReaderTheme.scrollDiagnosticsJs, contains('error'));
    });
  });
}

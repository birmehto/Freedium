import 'dart:convert';

import '../../features/settings/models/reader_settings.dart';
import '../../features/settings/models/reader_theme_mode.dart';

/// Builds the stylesheet and helper scripts injected into the reader WebView.
///
/// Everything here is deliberately defensive: the reader loads third-party
/// markup it does not control, so the stylesheet is reset-heavy and never
/// assumes a particular site structure.
abstract final class ReaderTheme {
  /// Id of the stylesheet used once a page has finished loading.
  static const String customCssId = 'custom-reader-style';

  /// Id of the stylesheet injected at document start to avoid a white flash
  /// before the page is ready. [injectCssScript] removes it once the real
  /// stylesheet is in place so the document never holds two copies.
  static const String _earlyCssId = 'freedium-early-flash-prevention';

  // ---------------------------------------------------------------------------
  // JavaScript compatibility
  // ---------------------------------------------------------------------------

  /// Polyfills for host-page code, not for Freedium's own scripts.
  ///
  /// These guard third-party bundles against older WebViews. Any WebView new
  /// enough to run the rest of the reader already implements them, so this is
  /// cheap insurance rather than a hot path.
  static const String esCompatPolyfills = '''
(function () {
  'use strict';

  if (!Array.prototype.at) {
    Array.prototype.at = function (index) {
      var length = this.length;
      var i = index < 0 ? length + index : index;
      return i >= 0 && i < length ? this[i] : undefined;
    };
  }

  if (!Array.prototype.findLast) {
    Array.prototype.findLast = function (callback, thisArg) {
      for (var i = this.length - 1; i >= 0; i--) {
        if (i in this && callback.call(thisArg, this[i], i, this)) {
          return this[i];
        }
      }

      return undefined;
    };
  }

  if (!Array.prototype.findLastIndex) {
    Array.prototype.findLastIndex = function (callback, thisArg) {
      for (var i = this.length - 1; i >= 0; i--) {
        if (i in this && callback.call(thisArg, this[i], i, this)) {
          return i;
        }
      }

      return -1;
    };
  }

  if (!Object.hasOwn) {
    Object.defineProperty(Object, 'hasOwn', {
      value: function (obj, prop) {
        if (obj == null) {
          throw new TypeError(
            'Cannot convert undefined or null to object'
          );
        }

        return Object.prototype.hasOwnProperty.call(
          Object(obj),
          prop,
        );
      },
      configurable: true,
      writable: true,
    });
  }
})();
''';

  // ---------------------------------------------------------------------------
  // Theme colors
  // ---------------------------------------------------------------------------

  static const _light = _ThemeColors(
    background: '#fbfaf7',
    text: '#2b2823',
    secondaryText: '#625d55',
    selection: 'rgba(43, 40, 35, 0.10)',
    codeBackground: '#f3f2ef',
    codeBorder: 'rgba(0, 0, 0, 0.10)',
    link: '#2563eb',
    quoteBar: '#d8d3c8',
  );

  static const _dark = _ThemeColors(
    background: '#1b1915',
    text: '#e7e1d6',
    secondaryText: '#b8b1a5',
    selection: 'rgba(231, 225, 214, 0.14)',
    codeBackground: '#24211c',
    codeBorder: 'rgba(255, 255, 255, 0.10)',
    link: '#7dd3fc',
    quoteBar: '#4a443b',
  );

  static const _sepia = _ThemeColors(
    background: '#f4ecd8',
    text: '#5b4636',
    secondaryText: '#7a6654',
    selection: 'rgba(91, 70, 54, 0.18)',
    codeBackground: '#ebe1c8',
    codeBorder: 'rgba(91, 70, 54, 0.15)',
    link: '#9a5b2c',
    quoteBar: '#d6c4a4',
  );

  static const _oled = _ThemeColors(
    background: '#000000',
    text: '#c9c7c2',
    secondaryText: '#999793',
    selection: 'rgba(201, 199, 194, 0.18)',
    codeBackground: '#111111',
    codeBorder: 'rgba(255, 255, 255, 0.12)',
    link: '#7dd3fc',
    quoteBar: '#3a3a3a',
  );

  static _ThemeColors _palette(
    ReaderThemeMode mode, {
    required bool systemDark,
  }) {
    return switch (mode) {
      ReaderThemeMode.system => systemDark ? _dark : _light,
      ReaderThemeMode.light => _light,
      ReaderThemeMode.dark => _dark,
      ReaderThemeMode.sepia => _sepia,
      ReaderThemeMode.oled => _oled,
    };
  }

  /// Whether the reader should render its text on a light or dark background.
  ///
  /// Kept separate from [_palette] because a theme can be visually dark while
  /// the reader still wants dark text, and vice versa.
  static bool readerIsDark(
    ReaderSettings settings, {
    required bool systemDark,
  }) {
    return switch (settings.themeMode) {
      ReaderThemeMode.system => systemDark,
      ReaderThemeMode.light => false,
      ReaderThemeMode.dark || ReaderThemeMode.oled => true,
      ReaderThemeMode.sepia => false,
    };
  }

  // ---------------------------------------------------------------------------
  // Early CSS
  // ---------------------------------------------------------------------------

  /// Injects the reader stylesheet at document start.
  ///
  /// Applied before the first paint so a light-themed user never sees a white
  /// flash on a dark background. The result is temporary: [injectCssScript]
  /// deletes it once the page is interactive.
  static String earlyStyleInjector({
    required ReaderSettings settings,
    required bool systemDark,
  }) {
    final css = getCss(settings: settings, systemDark: systemDark);

    return '''
(function() {
  try {
    var style = document.createElement('style');
    style.id = ${jsonEncode(_earlyCssId)};
    style.textContent = ${jsonEncode(css)};
    (document.head || document.documentElement).appendChild(style);
  } catch(e) {}
})();
''';
  }

  // ---------------------------------------------------------------------------
  // Popup handling
  // ---------------------------------------------------------------------------

  static const String popupBlockingJs = '''
(function () {
  'use strict';

  function silenceJsDialogs() {
    try {
      window.alert = function () {};

      window.confirm = function () {
        return false;
      };

      window.prompt = function () {
        return null;
      };

      try {
        Object.defineProperty(window, 'open', {
          value: function () {
            return null;
          },
          configurable: true,
          writable: false
        });
      } catch (err) {}
    } catch (err) {}
  }

  var POPUPS =
    '[data-dialog-content], [data-dialog-overlay], ' +
    '[data-drawer-content], [data-drawer-overlay], ' +
    '[data-dropdown-menu-content], [data-menu-content], ' +
    '[data-popover-content], [data-tooltip-content], ' +
    '[role="dialog"], [role="alertdialog"], [role="menu"], ' +
    '[data-sonner-toaster], [data-sonner-toast]';

  var hydrationReady = false;

  function stripPopups() {
    if (!hydrationReady) return;

    var nodes = document.querySelectorAll(POPUPS);

    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i];

      if (node && node.parentNode) {
        node.parentNode.removeChild(node);
      }
    }
  }

  function closest(el, selector) {
    while (el && el.nodeType === 1) {
      if (el.matches && el.matches(selector)) {
        return el;
      }

      el = el.parentElement;
    }

    return null;
  }

  document.addEventListener(
    'click',
    function (event) {
      var link = closest(event.target, 'a');

      if (link && link.target === '_blank') {
        event.preventDefault();
        event.stopImmediatePropagation();
      }
    },
    true,
  );

  if (window.MutationObserver) {
    new MutationObserver(function () {
      if (hydrationReady) {
        stripPopups();
      }
    }).observe(
      document.documentElement,
      {
        childList: true,
        subtree: true,
      },
    );
  }

  document.addEventListener(
    'DOMContentLoaded',
    function () {
      setTimeout(function () {
        hydrationReady = true;
        stripPopups();
      }, 350);
    },
  );

  silenceJsDialogs();
  stripPopups();
})();
''';

  // ---------------------------------------------------------------------------
  // Metadata
  // ---------------------------------------------------------------------------

  /// Reads article metadata out of the loaded document.
  ///
  /// Returns a JSON string (not an object) so the result survives
  /// `evaluateJavascript`, which stringifies its return value.
  static const String extractMetaJs = r'''
(function() {
  function meta(selector) {
    var el = document.querySelector(selector);

    return el
      ? (el.content || el.textContent || '').trim()
      : '';
  }

  function pick(selectors) {
    for (var i = 0; i < selectors.length; i++) {
      var value = meta(selectors[i]);

      if (value) {
        return value;
      }
    }

    return '';
  }

  var title = pick([
    'meta[property="og:title"]',
    'meta[name="twitter:title"]',
    'meta[name="title"]'
  ]) || document.title || '';

  var author = pick([
    'meta[name="author"]',
    'meta[name="twitter:creator"]',
    'meta[property="article:author"]'
  ]);

  if (
    author &&
    author.indexOf('?source=') !== -1
  ) {
    author = author.split('?source=')[0];
  }

  var publication = pick([
    'meta[property="og:site_name"]',
    'meta[name="twitter:site"]'
  ]);

  var publishedAt = pick([
    'meta[property="article:published_time"]',
    'meta[itemprop="datePublished"]',
    'meta[name="date"]'
  ]);

  var article =
    document.querySelector('article') ||
    document.querySelector('main') ||
    document.body;

  var text = article
    ? article.innerText || article.textContent || ''
    : '';

  var words = text
    .trim()
    .split(/\s+/)
    .filter(function(w) {
      return w.length > 0;
    })
    .length;

  return JSON.stringify({
    title: title,
    author: author,
    publication: publication,
    publishedAt: publishedAt,
    wordCount: words
  });
})();
''';

  // ---------------------------------------------------------------------------
  // CSS
  // ---------------------------------------------------------------------------

  /// Replaces the reader stylesheet in the loaded document.
  ///
  /// Also removes the [earlyStyleInjector] stylesheet. Without that cleanup the
  /// document would permanently hold two identical copies of the stylesheet,
  /// and re-injecting on every settings change would keep adding work for the
  /// style engine.
  ///
  /// [css] is JSON-encoded rather than interpolated into a template literal, so
  /// a backtick, `${…}` or a line separator in the generated stylesheet can
  /// never break out into executable JavaScript.
  static String injectCssScript(String css) {
    return '''
(function() {
  try {
    var early = document.getElementById(${jsonEncode(_earlyCssId)});
    if (early) early.remove();

    var previous = document.getElementById(${jsonEncode(customCssId)});
    if (previous) previous.remove();

    var style = document.createElement('style');
    style.id = ${jsonEncode(customCssId)};
    style.textContent = ${jsonEncode(css)};

    (document.head || document.documentElement).appendChild(style);
  } catch (e) {}
})();
''';
  }

  /// Builds the reader stylesheet for [settings].
  ///
  /// The generated CSS is a reset plus a small set of typographic rules: the
  /// reader removes the host page's layout chrome, so it also has to supply the
  /// rhythm (spacing, line height, heading scale) that chrome used to provide.
  static String getCss({
    required ReaderSettings settings,
    required bool systemDark,
  }) {
    final colors = _palette(settings.themeMode, systemDark: systemDark);
    final isDark = readerIsDark(settings, systemDark: systemDark);
    const m = _metrics;

    // The site may name a font the device does not have, so a chosen family is
    // always followed by a real fallback stack instead of being trusted alone.
    //
    // `fontFamily` is persisted as JSON and read back out of the database, so
    // it is treated as untrusted input here: anything that is not a plausible
    // family name is dropped rather than pasted into the stylesheet.
    // `System` is a sentinel meaning "whatever the device uses", not a family
    // name, so it must not be emitted as one.
    final family = settings.isSystemFont
        ? ''
        : _safeFontFamily(settings.fontFamily);
    final fontFamily = family.isEmpty ? '' : _fontFace(family);

    // Belt and braces for the same reason: a corrupted value must not be able
    // to push body text to an unreadable size.
    final fontSize = settings.fontSize.clamp(
      ReaderSettings.kMinFontSize,
      ReaderSettings.kMaxFontSize,
    );

    return '''
      /* ============================================================
         Theme
         ============================================================ */

      :root {
        color-scheme: ${isDark ? 'dark' : 'light'};
      }

      html {
        background: ${colors.background} !important;
        color: ${colors.text} !important;

        -webkit-text-size-adjust: 100% !important;

        /*
         * `anywhere` is the only value that reliably breaks a long URL in
         * narrow text, which is the single most common overflow source in
         * article bodies.
         */
        overflow-wrap: anywhere !important;
        word-break: break-word !important;
      }

      body {
        margin: 0 !important;
        padding: ${m.gutter}px !important;

        width: 100% !important;
        max-width: 100% !important;
        min-height: 100vh !important;

        box-sizing: border-box !important;

        background: ${colors.background} !important;
        color: ${colors.text} !important;

        font-size: ${fontSize}px !important;
        line-height: ${m.lineHeight} !important;

        -webkit-font-smoothing: antialiased !important;
        -moz-osx-font-smoothing: grayscale !important;

        /* Keep overscroll from revealing the white page behind the reader. */
        overscroll-behavior-y: none !important;

        $fontFamily
      }

      html,
      body {
        min-height: 100% !important;
      }

      body > div[style*="display: contents"] {
        display: block !important;
      }

      body > div[style*="display: contents"] > div {
        min-height: 0 !important;
      }

      /* ============================================================
         Main layout
         ============================================================ */

      main {
        width: 100% !important;
        max-width: none !important;
        min-height: 0 !important;

        margin: 0 auto !important;
        padding: 0 !important;

        color: ${colors.text} !important;
      }

      article {
        width: 100% !important;
        min-height: 0 !important;

        margin-left: auto !important;
        margin-right: auto !important;

        padding: 0 !important;

        overflow: visible !important;

        background: transparent !important;
        color: ${colors.text} !important;

        border: 0 !important;
        border-radius: 0 !important;
        box-shadow: none !important;
      }

      article .prose {
        max-width: none !important;
        padding: 0 !important;

        background: transparent !important;
        color: ${colors.text} !important;
      }

      /* ============================================================
         Article text
         ============================================================ */

      article > header,
      article > header h1,
      article > header h2,
      article > header h3,
      article > header p,
      article > header span,
      article > header div {
        color: ${colors.text} !important;
      }

      article .prose,
      article .prose p,
      article .prose li,
      article .prose blockquote,
      article .prose h1,
      article .prose h2,
      article .prose h3,
      article .prose h4,
      article .prose h5,
      article .prose h6,
      article .prose strong,
      article .prose em,
      article .prose figcaption {
        color: ${colors.text} !important;
      }

      article > div > p,
      article > div > h1,
      article > div > h2,
      article > div > h3,
      article > div > h4,
      article > div > h5,
      article > div > h6,
      article > div > span {
        color: ${colors.text} !important;
      }

      article small,
      article .text-sm,
      article .text-xs {
        color: ${colors.secondaryText} !important;
      }

      /* ============================================================
         Rhythm
         ============================================================ */

      /*
       * The host page's own margins are tuned for its layout, which the reader
       * has already removed, so vertical rhythm is re-established here.
       */
      article > * + *,
      article .prose > * + * {
        margin-top: ${m.paragraphSpacing}em !important;
      }

      article > header > * + * {
        margin-top: ${m.paragraphSpacing * 0.5}em !important;
      }

      p {
        margin-bottom: 0 !important;

        /* Avoid a single-word last line. Ignored where unsupported. */
        text-wrap: pretty !important;
      }

      /* ============================================================
         Headings
         ============================================================ */

      article h1,
      article h2,
      article h3,
      article h4,
      article h5,
      article h6,
      article .prose h1,
      article .prose h2,
      article .prose h3,
      article .prose h4,
      article .prose h5,
      article .prose h6 {
        color: ${colors.text} !important;

        line-height: ${m.headingLineHeight} !important;
        font-weight: 700 !important;
        letter-spacing: -0.01em !important;

        /* Headings are short, so even out the line lengths. */
        text-wrap: balance !important;
      }

      article h1,
      article .prose h1 {
        font-size: 1.75em !important;
        margin-bottom: 0 !important;
      }

      article h2,
      article .prose h2 {
        font-size: 1.4em !important;
        margin-bottom: 0 !important;
      }

      article h3,
      article .prose h3 {
        font-size: 1.2em !important;
        margin-bottom: 0 !important;
      }

      article h4,
      article .prose h4,
      article h5,
      article .prose h5,
      article h6,
      article .prose h6 {
        font-size: 1em !important;
        margin-bottom: 0 !important;
      }

      /* ============================================================
         Blockquotes
         ============================================================ */

      article blockquote,
      article .prose blockquote,
      article > div > blockquote {
        margin-top: ${m.paragraphSpacing}em !important;
        margin-bottom: 0 !important;

        padding: 0.1em 0 0.1em ${m.quoteIndent}em !important;

        border: 0 !important;
        border-left: 3px solid ${colors.quoteBar} !important;
        border-radius: 0 !important;

        background: transparent !important;

        color: ${colors.secondaryText} !important;
      }

      article blockquote p,
      article .prose blockquote p {
        color: inherit !important;
      }

      /* ============================================================
         Lists
         ============================================================ */

      article ul,
      article ol,
      article .prose ul,
      article .prose ol {
        margin-top: ${m.paragraphSpacing}em !important;
        margin-bottom: 0 !important;

        padding-left: ${m.listIndent}em !important;
      }

      article ul,
      article .prose ul {
        list-style: disc !important;
      }

      article ol,
      article .prose ol {
        list-style: decimal !important;
      }

      article li::marker,
      article .prose li::marker {
        color: ${colors.secondaryText} !important;
      }

      /* ============================================================
         Links
         ============================================================ */

      article .prose a,
      article a {
        color: ${colors.link} !important;

        text-decoration: underline !important;
        text-underline-offset: 2px !important;
        text-decoration-thickness: from-font !important;
      }

      /* ============================================================
         Selection
         ============================================================ */

      ::selection {
        background: ${colors.selection} !important;
      }

      /* ============================================================
         Images / media
         ============================================================ */

      img,
      video,
      iframe {
        max-width: 100% !important;
      }

      img,
      video {
        height: auto !important;
      }

      img {
        /*
         * Defers decoding and layout for images below the fold, which is where
         * most of a long article's image weight sits.
         */
        content-visibility: auto !important;
        contain-intrinsic-size: auto 300px;
      }

      figure {
        margin: ${m.paragraphSpacing}em 0 0 !important;
      }

      figcaption {
        margin-top: ${m.paragraphSpacing * 0.5}em !important;
        color: ${colors.secondaryText} !important;
        font-size: 0.85em !important;
      }

      /* ============================================================
         INLINE CODE
         ============================================================ */

      article .prose :not(pre) > code,
      article code:not(pre code) {
        display: inline-block !important;

        background: ${isDark ? 'rgba(255, 255, 255, 0.10)' : 'rgba(0, 0, 0, 0.06)'} !important;

        color: ${colors.text} !important;

        padding: 0.12em 0.35em !important;

        border-radius: ${m.radiusSm}em !important;

        border: 0 !important;

        font-size: 0.9em !important;
        font-weight: 500 !important;

        white-space: normal !important;
      }

      /* ============================================================
         CODE BLOCK
         ============================================================ */

      pre {
        width: 100% !important;
        max-width: 100% !important;

        box-sizing: border-box !important;

        overflow-x: auto !important;
        overflow-y: hidden !important;

        -webkit-overflow-scrolling: touch !important;

        margin: ${m.paragraphSpacing}em 0 0 !important;

        padding: ${m.codePadding}px !important;

        background: ${colors.codeBackground} !important;

        border: 1px solid ${colors.codeBorder} !important;

        border-radius: ${m.radiusMd}px !important;

        color: ${colors.text} !important;

        font-size: 0.9em !important;
        line-height: ${m.codeLineHeight} !important;

        /* Indentation has to survive a horizontal scroll. */
        tab-size: ${m.tabSize} !important;
      }

      /*
       * The code element inside a block must not add a second background,
       * border or padding.
       */
      pre > code,
      pre code {
        display: block !important;

        max-width: none !important;

        padding: 0 !important;

        margin: 0 !important;

        background: transparent !important;

        border: 0 !important;

        border-radius: 0 !important;

        font-size: inherit !important;

        line-height: inherit !important;

        white-space: pre !important;

        /*
         * Inherits from `pre` rather than forcing a color, so site syntax
         * highlighting on child spans stays intact.
         */
        color: inherit !important;
      }

      /*
       * Clear the background some highlighters paint on wrappers, but leave
       * their colors alone: those colors are the syntax highlighting.
       */
      pre span,
      pre div {
        background-color: transparent !important;
      }

      pre button {
        color: inherit !important;
      }

      /* ============================================================
         Tables
         ============================================================ */

      table {
        display: block !important;

        max-width: 100% !important;

        overflow-x: auto !important;

        box-sizing: border-box !important;

        color: ${colors.text} !important;
      }

      th,
      td {
        padding: ${m.radiusSm}em ${m.quoteIndent}em !important;
        border-bottom: 1px solid ${colors.codeBorder} !important;
      }

      th {
        color: ${colors.secondaryText} !important;
        font-weight: 600 !important;
        text-align: left !important;
      }

      /* ============================================================
         Site chrome
         ============================================================ */

      nav#header,
      .header-nav,
      footer,
      #progress,
      [role="banner"],
      [role="contentinfo"],
      section[aria-label*="Notifications"],
      [role="region"][aria-label*="Notifications"] {
        display: none !important;
      }

      /* ============================================================
         Article structure
         ============================================================ */

      article > header {
        padding: 0 0 ${m.paragraphSpacing}em !important;

        background: transparent !important;

        border: 0 !important;
      }

      article > div:not([data-nosnippet]) {
        padding: 0 !important;

        background: transparent !important;

        border: 0 !important;
      }

      article > div[data-nosnippet],
      article nav,
      article > section[aria-labelledby="toc-heading"] {
        display: none !important;
      }

      /* ============================================================
         Popups
         ============================================================ */

      [role="dialog"],
      [role="alertdialog"],
      [role="menu"],
      [data-dialog-content],
      [data-dialog-overlay],
      [data-drawer-content],
      [data-drawer-overlay],
      [data-dropdown-menu-content],
      [data-menu-content],
      [data-popover-content],
      [data-tooltip-content],
      [data-slot][data-slot\$="-overlay"],
      [data-sonner-toaster],
      [data-sonner-toast] {
        display: none !important;
      }

      /* ============================================================
         Accessibility
         ============================================================ */

      /*
       * The reader strips site chrome, so keyboard focus needs its own visible
       * ring. `:focus-visible` keeps it off mouse taps.
       */
      :focus-visible {
        outline: 2px solid ${colors.link} !important;
        outline-offset: 2px !important;
        border-radius: ${m.radiusSm}px !important;
      }

      /* ============================================================
         Image zoom
         ============================================================ */

      .image-zoom-figure,
      [data-zoom-src] {
        cursor: zoom-in !important;
      }

      /* ============================================================
         Overflow protection
         ============================================================ */

      pre,
      table,
      .overflow-x-auto {
        max-width: 100% !important;
      }
    ''';
  }

  /// Emits a `font-family` declaration that survives a font the device lacks.
  static String _fontFace(String family) =>
      '''
          font-family: "$family", ${_metrics.fallbackStack} !important;
        ''';

  /// Reduces [family] to a value that is safe to paste into a stylesheet.
  ///
  /// Returns an empty string -- meaning "use the reader's system font" --
  /// whenever the value is empty, oversized, or contains anything other than
  /// characters that occur in real family names. A value is never partially
  /// repaired: silently rewriting `Merriweather"><script>` into a different
  /// font would hide a corrupt preference instead of discarding it.
  static String _safeFontFamily(String family) {
    if (family.isEmpty || family.length > _maxFontNameLength) return '';
    if (_unsafeFontChars.hasMatch(family)) return '';

    final trimmed = family.trim();

    return trimmed.isEmpty ? '' : trimmed;
  }

  /// Quotes, braces, semicolons, backslashes and comment markers would let a
  /// tampered preferences value inject arbitrary declarations.
  static final RegExp _unsafeFontChars = RegExp('[^A-Za-z0-9 -]');

  static const int _maxFontNameLength = 64;

  /// Typographic constants for the reader, so the stylesheet does not carry
  /// unexplained magic numbers.
  static const _ReaderMetrics _metrics = _ReaderMetrics();
}

class _ReaderMetrics {
  const _ReaderMetrics();

  /// Horizontal breathing room between the page edge and the article.
  final double gutter = 16;

  /// Body line height. Comfortable for long-form prose at any font size.
  final double lineHeight = 1.7;

  /// Headings are tighter than body copy so they read as separate blocks.
  final double headingLineHeight = 1.3;

  final double codeLineHeight = 1.6;

  /// Vertical space between sibling blocks, in `em` so it tracks font size.
  final double paragraphSpacing = 1.1;

  final double quoteIndent = 1.1;

  final double listIndent = 1.5;

  final int codePadding = 16;

  final int tabSize = 2;

  final double radiusSm = 6;

  final double radiusMd = 12;

  /// Appended to a user-chosen font so an unavailable family still renders.
  final String fallbackStack = 'system-ui, -apple-system, Roboto, sans-serif';
}

class _ThemeColors {
  const _ThemeColors({
    required this.background,
    required this.text,
    required this.secondaryText,
    required this.selection,
    required this.codeBackground,
    required this.codeBorder,
    required this.link,
    required this.quoteBar,
  });

  final String background;
  final String text;
  final String secondaryText;
  final String selection;
  final String codeBackground;
  final String codeBorder;

  /// Link color, tuned per theme for contrast against [background].
  final String link;

  /// Left rule on blockquotes.
  final String quoteBar;
}

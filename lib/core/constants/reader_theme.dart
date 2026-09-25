import 'dart:convert';

import '../../features/settings/models/reader_settings.dart';
import '../../features/settings/models/reader_theme_mode.dart';

class ReaderTheme {
  ReaderTheme._();

  static const String customCssId = 'custom-reader-style';
  static const String _earlyCssId = 'freedium-early-flash-prevention';

  // ---------------------------------------------------------------------------
  // JavaScript compatibility
  // ---------------------------------------------------------------------------

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
  );

  static const _dark = _ThemeColors(
    background: '#1b1915',
    text: '#e7e1d6',
    secondaryText: '#b8b1a5',
    selection: 'rgba(231, 225, 214, 0.14)',
    codeBackground: '#24211c',
    codeBorder: 'rgba(255, 255, 255, 0.10)',
  );

  static const _sepia = _ThemeColors(
    background: '#f4ecd8',
    text: '#5b4636',
    secondaryText: '#7a6654',
    selection: 'rgba(91, 70, 54, 0.18)',
    codeBackground: '#ebe1c8',
    codeBorder: 'rgba(91, 70, 54, 0.15)',
  );

  static const _oled = _ThemeColors(
    background: '#000000',
    text: '#c9c7c2',
    secondaryText: '#999793',
    selection: 'rgba(201, 199, 194, 0.18)',
    codeBackground: '#111111',
    codeBorder: 'rgba(255, 255, 255, 0.12)',
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

  static String earlyStyleInjector({
    required ReaderSettings settings,
    required bool systemDark,
  }) {
    final css = getCss(settings: settings, systemDark: systemDark);

    return '''
(function() {
  try {
    var style = document.createElement('style');
    style.id = '$_earlyCssId';
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

  /// Script that replaces the reader stylesheet inside the loaded document.
  ///
  /// [css] is JSON-encoded rather than interpolated into a template literal, so
  /// a backtick, `${…}` or a line separator in the generated stylesheet can never
  /// break out into executable JavaScript.
  static String injectCssScript(String css) {
    return '''
(function() {
  try {
    var previous = document.getElementById('${jsonEncode(customCssId)}');
    if (previous) previous.remove();

    var style = document.createElement('style');
    style.id = ${jsonEncode(customCssId)};
    style.textContent = ${jsonEncode(css)};

    (document.head || document.documentElement).appendChild(style);
  } catch (e) {}
})();
''';
  }

  static String getCss({
    required ReaderSettings settings,
    required bool systemDark,
  }) {
    final colors = _palette(settings.themeMode, systemDark: systemDark);

    final isDark = readerIsDark(settings, systemDark: systemDark);

    final linkColor = isDark ? '#7dd3fc' : '#2563eb';

    final inlineCodeBackground = isDark
        ? 'rgba(255, 255, 255, 0.10)'
        : 'rgba(0, 0, 0, 0.06)';

    final fontFamily = settings.isSystemFont
        ? ''
        : '''
          font-family: ${settings.fontFamily} !important;
        ''';

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
      }

      body {
        margin: 0 !important;
        padding: 16px !important;

        width: 100% !important;
        max-width: 100% !important;
        min-height: 100vh !important;

        box-sizing: border-box !important;

        overflow-wrap: anywhere !important;

        background: ${colors.background} !important;
        color: ${colors.text} !important;

        font-size: ${settings.fontSize}px !important;

        -webkit-font-smoothing: antialiased !important;

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
         Links
         ============================================================ */

      article .prose a {
        color: $linkColor !important;

        text-decoration: underline !important;
        text-underline-offset: 2px !important;
      }

      /* ============================================================
         Selection
         ============================================================ */

      ::selection {
        background: ${colors.selection} !important;
      }

      /* ============================================================
         Paragraph spacing
         ============================================================ */

      p {
        margin-top: 0 !important;
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
        content-visibility: auto !important;
        contain-intrinsic-size: auto 300px;
      }

      /* ============================================================
         INLINE CODE
         ============================================================ */

      article .prose :not(pre) > code {
        display: inline-block !important;

        background: $inlineCodeBackground !important;

        color: ${colors.text} !important;

        padding: 0.12em 0.35em !important;

        border-radius: 0.35em !important;

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

        margin: 1.5em 0 !important;

        padding: 16px !important;

        background: ${colors.codeBackground} !important;

        border: 1px solid ${colors.codeBorder} !important;

        border-radius: 12px !important;

        color: ${colors.text} !important;

        font-size: 0.9em !important;

        line-height: 1.6 !important;
      }

      /*
       * The actual code element should not add another
       * background or border.
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
      }

      /*
       * Remove unwanted backgrounds from syntax-highlight
       * wrappers, but DO NOT override their colors.
       *
       * This preserves Freedium's syntax highlighting.
       */
      pre span,
      pre div {
        background-color: transparent !important;
      }

      /*
       * Only provide a fallback color when an element does
       * not already have a syntax-highlighting color.
       */
      pre {
        --reader-code-color: ${colors.text};
      }

      /* ============================================================
         CODE COPY BUTTON
         ============================================================ */

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
        padding: 0 0 1.5em !important;

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
}

class _ThemeColors {
  const _ThemeColors({
    required this.background,
    required this.text,
    required this.secondaryText,
    required this.selection,
    required this.codeBackground,
    required this.codeBorder,
  });

  final String background;
  final String text;
  final String secondaryText;
  final String selection;
  final String codeBackground;
  final String codeBorder;
}

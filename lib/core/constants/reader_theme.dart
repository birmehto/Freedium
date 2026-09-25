import 'dart:convert';

import '../../features/settings/models/reader_settings.dart';
import '../../features/settings/models/reader_theme_mode.dart';

class ReaderTheme {
  ReaderTheme._();

  static const String customCssId = 'custom-reader-style';
  static const String _earlyCssId = 'freedium-early-flash-prevention';

  /// ES2022/ES2023 polyfills for older Android WebViews that still load the
  /// Freedium Svelte bundle. Prevents
  /// "TypeError: ?.at / e.findLast is not a function".
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
          throw new TypeError('Cannot convert undefined or null to object');
        }
        return Object.prototype.hasOwnProperty.call(Object(obj), prop);
      },
      configurable: true,
      writable: true
    });
  }
})();
''';

  static const _light = _ThemeColors(
    background: '#fbfaf7',
    text: '#2b2823',
    selection: 'rgba(43, 40, 35, 0.10)',
  );

  static const _dark = _ThemeColors(
    background: '#1b1915',
    text: '#e7e1d6',
    selection: 'rgba(231, 225, 214, 0.14)',
  );

  static const _sepia = _ThemeColors(
    background: '#f4ecd8',
    text: '#5b4636',
    selection: 'rgba(91, 70, 54, 0.18)',
  );

  static const _oled = _ThemeColors(
    background: '#000000',
    text: '#c9c7c2',
    selection: 'rgba(201, 199, 194, 0.18)',
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

  /// Effective theme of an explicit reader theme given the app's brightness.
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

  static String earlyStyleInjector({
    required ReaderSettings settings,
    required bool systemDark,
  }) {
    final css = getCss(settings: settings, systemDark: systemDark);

    return '''
(function() {
  try {
    var s = document.createElement('style');
    s.id = '$_earlyCssId';
    s.textContent = ${jsonEncode(css)};
    (document.head || document.documentElement).appendChild(s);
  } catch(e) {}
})();
''';
  }

  static const String popupBlockingJs = '''
(function () {
  'use strict';

  function silenceJsDialogs() {
    try {
      window.alert = function () {};
      window.confirm = function () { return false; };
      window.prompt = function () { return null; };
      try {
        Object.defineProperty(window, 'open', {
          value: function () { return null; },
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
      if (node && node.parentNode) node.parentNode.removeChild(node);
    }
  }

  function closest(el, selector) {
    while (el && el.nodeType === 1) {
      if (el.matches && el.matches(selector)) return el;
      el = el.parentElement;
    }
    return null;
  }

  document.addEventListener('click', function (event) {
    var link = closest(event.target, 'a');
    if (link && link.target === '_blank') {
      event.preventDefault();
      event.stopImmediatePropagation();
      return;
    }
    var trigger = closest(
      event.target,
      '[data-zoom-src], .image-zoom-figure, [data-dialog-trigger], ' +
      '[data-drawer-trigger], [data-popover-trigger], ' +
      '[data-dropdown-menu-trigger], button[aria-haspopup]'
    );
    if (trigger) {
      event.preventDefault();
      event.stopImmediatePropagation();
    }
  }, true);

  if (window.MutationObserver) {
    new MutationObserver(function () {
      if (hydrationReady) stripPopups();
    }).observe(
      document.documentElement,
      { childList: true, subtree: true }
    );
  }
  document.addEventListener('DOMContentLoaded', function () {
    setTimeout(function () {
      hydrationReady = true;
      stripPopups();
    }, 350);
  });
  silenceJsDialogs();
  stripPopups();
})();
''';

  /// JavaScript to extract article word count for reading-time estimation.
  static const String extractArticleTextJs = r'''
(function() {
  try {
    var article = document.querySelector('article') || document.querySelector('main') || document.body;
    var text = article ? article.innerText || article.textContent || '' : '';
    var words = text.trim().split(/\s+/).filter(function(w) { return w.length > 0; }).length;
    return JSON.stringify({ words: words });
  } catch(e) {
    return JSON.stringify({ words: 0 });
  }
})();
''';

  /// JavaScript to read rich metadata (title, author, publication, date).
  static const String extractMetaJs = r'''
(function() {
  function meta(selector) {
    var el = document.querySelector(selector);
    return el ? (el.content || el.textContent || '').trim() : '';
  }
  function pick(selectors) {
    for (var i = 0; i < selectors.length; i++) {
      var v = meta(selectors[i]);
      if (v) return v;
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
  if (author && author.indexOf('?source=') !== -1) author = author.split('?source=')[0];
  var publication = pick([
    'meta[property="og:site_name"]',
    'meta[name="twitter:site"]'
  ]);
  var publishedAt = pick([
    'meta[property="article:published_time"]',
    'meta[itemprop="datePublished"]',
    'meta[name="date"]'
  ]);
  var article = document.querySelector('article') || document.querySelector('main') || document.body;
  var text = article ? article.innerText || article.textContent || '' : '';
  var words = text.trim().split(/\s+/).filter(function(w) { return w.length > 0; }).length;
  return JSON.stringify({
    title: title,
    author: author,
    publication: publication,
    publishedAt: publishedAt,
    wordCount: words
  });
})();
''';

  static const String captureArticleHtmlJs = '''
(function() {
  try {
    var source = document.querySelector('article') || document.querySelector('main');
    if (!source) {
      return JSON.stringify({ html: '', images: 0 });
    }

    var clone = source.cloneNode(true);
    var images = clone.querySelectorAll('img').length;
    var unwanted = clone.querySelectorAll(
      'nav, footer, #progress, [data-nosnippet], ' +
      'section[aria-label*="Notifications"], ' +
      '[role="region"][aria-label*="Notifications"], ' +
      'section[aria-labelledby="toc-heading"], ' +
      '[data-dialog-content], [data-dialog-overlay], ' +
      '[data-drawer-content], [data-drawer-overlay], ' +
      '[data-dropdown-menu-content], [data-menu-content], ' +
      '[data-popover-content], [data-tooltip-content], ' +
      '[role="dialog"], [role="alertdialog"], [role="menu"], ' +
      '[data-sonner-toaster], [data-sonner-toast]'
    );
    for (var i = 0; i < unwanted.length; i++) {
      if (unwanted[i] && unwanted[i].parentNode) {
        unwanted[i].parentNode.removeChild(unwanted[i]);
      }
    }

    function makeAbsolute(attribute) {
      var nodes = clone.querySelectorAll('[' + attribute + ']');
      for (var j = 0; j < nodes.length; j++) {
        var value = nodes[j].getAttribute(attribute);
        if (!value || value.charAt(0) === '#') continue;
        try {
          var resolver = document.createElement('a');
          resolver.href = value;
          nodes[j].setAttribute(attribute, resolver.href);
        } catch (e) {}
      }
    }

    makeAbsolute('href');
    makeAbsolute('src');
    makeAbsolute('data-zoom-src');

    var base = (document.baseURI || '').replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
    var html = '<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><base href="' + base + '"></head><body>' + clone.outerHTML + '</body></html>';
    return JSON.stringify({ html: html, images: images });
  } catch(e) {
    return JSON.stringify({ html: '', images: 0 });
  }
})();
''';

  /// Selected text when present, otherwise the (truncated) body text.
  static const String selectedOrBodyTextJs = r'''
(function() {
  try {
    var sel = window.getSelection ? window.getSelection().toString() : '';
    if (sel && sel.trim()) return JSON.stringify({ text: sel });
  } catch(e) {}
  try {
    var article = document.querySelector('article') || document.querySelector('main') || document.body;
    var text = article ? article.innerText || article.textContent || '' : '';
    var clean = text.split(/\s+/).filter(function(w){ return w.length > 0; }).join(' ');
    return JSON.stringify({ text: clean.substring(0, 20000) });
  } catch(e) {
    return JSON.stringify({ text: '' });
  }
})();
''';

  static String getCss({
    required ReaderSettings settings,
    required bool systemDark,
  }) {
    final colors = _palette(settings.themeMode, systemDark: systemDark);
    final fontFamily = settings.isSystemFont
        ? ''
        : '\n        font-family: ${settings.fontFamily} !important;';

    return '''
      :root {
        color-scheme: ${readerIsDark(settings, systemDark: systemDark) ? 'dark' : 'light'};
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

      main {
        width: 100% !important;
        max-width: none !important;
        min-height: 0 !important;
        margin: 0 auto !important;
        padding: 0 !important;
      }

      ::selection {
        background: ${colors.selection} !important;
      }

      article {
        width: 100% !important;
        min-height: 0 !important;
        margin-left: auto !important;
        margin-right: auto !important;
        padding: 0 !important;
        overflow: visible !important;
        background: transparent !important;
        border: 0 !important;
        border-radius: 0 !important;
        box-shadow: none !important;
        color: ${colors.text} !important;
      }

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

      article .prose {
        max-width: none !important;
        padding: 0 !important;
      }

      p {
        margin-top: 0 !important;
      }

      p,
      div,
      section,
      article,
      main,
      aside,
      img,
      video,
      iframe,
      table,
      pre {
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

      /* ================================
         Remove site chrome
         ================================ */

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

      /* ================================
         Remove popups
         ================================ */

      [data-dialog-trigger],
      [data-drawer-trigger],
      [data-dropdown-menu-trigger],
      button[aria-haspopup="dialog"] {
        display: none !important;
      }

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

      .image-zoom-figure,
      [data-zoom-src] {
        pointer-events: none !important;
        cursor: default !important;
      }
    ''';
  }
}

class _ThemeColors {
  const _ThemeColors({
    required this.background,
    required this.text,
    required this.selection,
  });
  final String background;
  final String text;
  final String selection;
}

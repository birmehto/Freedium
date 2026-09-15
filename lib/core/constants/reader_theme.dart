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

  /// Inject minimal CSS at document start to prevent white/dark flash.
  /// Must be safe for injection before DOM is fully ready.
  static String earlyStyleInjector({required bool isDarkMode}) {
    final bg = isDarkMode ? _dark.background : _light.background;
    final fg = isDarkMode ? _dark.text : _light.text;
    final scheme = isDarkMode ? 'dark' : 'light';

    return '''
(function() {
  try {
    var s = document.createElement('style');
    s.id = '$_earlyCssId';
    s.textContent = 'html, body { background: $bg !important; color: $fg !important; color-scheme: $scheme !important; transition: none !important; } * { transition: none !important; }';
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

  /// JavaScript to extract article text for reading time estimation.
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

  static String getCss({required bool isDarkMode, double fontSize = 17.0}) {
    final colors = isDarkMode ? _dark : _light;

    return '''
      :root {
        color-scheme: ${isDarkMode ? 'dark' : 'light'};
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

        font-size: ${fontSize}px !important;
        line-height: 1.8 !important;
        -webkit-font-smoothing: antialiased !important;
      }

      ::selection {
        background: ${colors.selection} !important;
      }

      article {
        max-width: 42em !important;
        margin-left: auto !important;
        margin-right: auto !important;
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

      /* Freedium header nav, footer, top progress bar, notifications */

      nav#header,
      .header-nav,
      footer,
      #progress,
      section[aria-label*="Notifications"],
      [role="region"][aria-label*="Notifications"] {
        display: none !important;
      }

      /* Article toolbars (back / share / open original) */

      article nav {
        display: none !important;
      }

      /* Contents + "Download article" section */

      section[aria-labelledby="toc-heading"] {
        display: none !important;
      }

      /* ================================
         Remove popups
         ================================ */

      /* Triggers: report-problem dialog, drawers, dropdown menus */

      [data-dialog-trigger],
      [data-drawer-trigger],
      [data-dropdown-menu-trigger],
      button[aria-haspopup="dialog"] {
        display: none !important;
      }

      /* Popup surfaces */

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

      /* Disable click-to-zoom lightbox on the cover image */

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

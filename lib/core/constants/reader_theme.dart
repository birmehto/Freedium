class ReaderTheme {
  ReaderTheme._();

  static const String customCssId = 'custom-reader-style';

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
    link: '#7a6a50',
    codeBackground: '#f0ede6',
    codeText: '#4a453d',
    quoteBorder: '#dcd5c8',
    quoteText: '#7c7568',
    border: '#e8e4db',
    selection: 'rgba(43, 40, 35, 0.10)',
  );

  static const _dark = _ThemeColors(
    background: '#1b1915',
    text: '#e7e1d6',
    link: '#c0b298',
    codeBackground: '#262319',
    codeText: '#d8d1c4',
    quoteBorder: '#4a4438',
    quoteText: '#a89f8f',
    border: '#333028',
    selection: 'rgba(231, 225, 214, 0.14)',
  );

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

  static String getCss({
    required bool isDarkMode,
    double fontSize = 17.0,
    String fontFamily = 'Source Serif 4',
  }) {
    final colors = isDarkMode ? _dark : _light;
    final fontUrl = _getGoogleFontUrl(fontFamily);
    final fallback = _getFallbackFont(fontFamily);

    return '''
      /* ================================
         Reader Theme
         ================================ */

      @import url('$fontUrl');

      :root {
        color-scheme: ${isDarkMode ? 'dark' : 'light'};
      }

      html {
        background: ${colors.background} !important;
        color: ${colors.text} !important;
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

        font-family: '$fontFamily', $fallback !important;
        font-size: ${fontSize}px !important;
        line-height: 1.8 !important;

        -webkit-font-smoothing: antialiased !important;
        text-rendering: optimizeLegibility !important;
      }

      /* ================================
         Ensure document-level scrolling
         ================================ */

      html,
      body {
        height: auto !important;
      }

      html {
        overflow-y: auto !important;
      }

      ::selection {
        background: ${colors.selection} !important;
      }

      /* ================================
         Reading column
         ================================ */

      article {
        max-width: 42em !important;
        margin-left: auto !important;
        margin-right: auto !important;
        text-align: left !important;
      }

      /* ================================
         Typography
         ================================ */

      body,
      body p,
      body div,
      body span,
      body li,
      body dt,
      body dd,
      body blockquote,
      body strong,
      body b,
      body em,
      body i,
      body small,
      body time,
      body figure,
      body figcaption,
      body address,
      body caption {
        font-family: inherit !important;
        color: inherit !important;
      }

      p {
        margin: 0 0 1.25em !important;
      }

      h1,
      h2,
      h3,
      h4,
      h5,
      h6 {
        margin-top: 1.6em !important;
        margin-bottom: 0.55em !important;

        font-family: inherit !important;
        font-weight: 600 !important;
        line-height: 1.35 !important;
        letter-spacing: -0.01em !important;
        color: inherit !important;
      }

      h1 {
        font-size: 2em !important;
        line-height: 1.25 !important;
        letter-spacing: -0.02em !important;
      }

      h2 {
        font-size: 1.55em !important;
      }

      h3 {
        font-size: 1.3em !important;
      }

      h4 {
        font-size: 1.15em !important;
      }

      h5,
      h6 {
        font-size: 1em !important;
      }

      strong,
      b {
        font-weight: 700 !important;
      }

      em,
      i {
        font-style: italic !important;
      }

      /* ================================
         Links
         ================================ */

      a {
        color: ${colors.link} !important;
        text-decoration: none !important;
        border-bottom: 1px solid ${colors.quoteBorder} !important;
      }

      a:hover {
        text-decoration: underline !important;
        border-bottom-color: transparent !important;
      }

      /* ================================
         Blockquotes
         ================================ */

      blockquote {
        margin: 1.75em 0 !important;
        padding: 0.35em 0 0.35em 1.35em !important;

        border-left: 2px solid ${colors.quoteBorder} !important;

        color: ${colors.quoteText} !important;
        font-style: italic !important;
      }

      /* ================================
         Code
         ================================ */

      code {
        padding: 2px 6px !important;
        border-radius: 4px !important;

        background: ${colors.codeBackground} !important;
        color: ${colors.codeText} !important;

        font-family:
          'SFMono-Regular',
          Consolas,
          'Liberation Mono',
          Menlo,
          monospace !important;

        font-size: 0.88em !important;
      }

      pre {
        margin: 1.75em 0 !important;
        padding: 16px !important;

        max-width: 100% !important;
        overflow-x: auto !important;
        white-space: pre-wrap !important;
        overflow-wrap: anywhere !important;

        border-radius: 8px !important;
        border: 1px solid ${colors.border} !important;

        background: ${colors.codeBackground} !important;
        color: ${colors.codeText} !important;

        font-family:
          'SFMono-Regular',
          Consolas,
          'Liberation Mono',
          Menlo,
          monospace !important;

        font-size: 0.92em !important;
        line-height: 1.6 !important;
      }

      pre code {
        padding: 0 !important;
        background: transparent !important;
      }

      /* ================================
         Media
         ================================ */

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
        border-radius: 6px !important;
      }

      figcaption {
        color: ${colors.quoteText} !important;
        font-size: 0.9em !important;
      }

      iframe {
        border: 0 !important;
      }

      /* ================================
         Neutralize site backgrounds
         ================================ */

      article,
      main,
      aside,
      section,
      header,
      footer,
      figure,
      figcaption,
      div,
      p,
      ul,
      ol,
      table,
      thead,
      tbody,
      tr,
      th,
      td,
      blockquote {
        background: transparent !important;
      }

      article,
      main,
      section,
      header,
      footer {
        border-radius: 0 !important;
        box-shadow: none !important;
      }

      /* ================================
         Tables
         ================================ */

      table {
        display: block !important;
        width: 100% !important;
        max-width: 100% !important;
        overflow-x: auto !important;

        border-collapse: collapse !important;
      }

      th,
      td {
        padding: 8px !important;
        border: 1px solid ${isDarkMode ? '#44474b' : '#d9d9d9'} !important;
      }

      /* ================================
         Lists
         ================================ */

      ul,
      ol {
        padding-left: 24px !important;
      }

      li {
        margin-bottom: 0.4em !important;
      }

      /* ================================
         Remove unwanted website UI
         ================================ */

      .paywall,
      .subscription-banner,
      .premium-banner,
      .navbar,
      #progress,
      #darkModeToggle,
      #openProblemModal,
      .theme-toggle,
      .storage-notification-container,
      .fixed.bottom-4.left-4 {
        display: none !important;
      }

      /* Freedium site chrome: header nav, donate bar, footer */

      nav#header,
      .header-nav,
      footer {
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

      /* Kill popup surfaces: dialogs, menus, drawers, popovers */

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
      button[aria-haspopup="dialog"],
      [data-dialog-trigger],
      [data-dropdown-menu-trigger],
      [data-drawer-trigger],
      [data-popover-trigger] {
        display: none !important;
      }

      /* Disable click-to-zoom lightbox on cover/article images */

      .image-zoom-figure,
      [data-zoom-src] {
        pointer-events: none !important;
        cursor: default !important;
      }

      /* Toast / snackbar region (sonner notifications) */

      section[aria-label*="Notifications"],
      [role="region"][aria-label*="Notifications"],
      [data-sonner-toaster],
      [data-sonner-toast] {
        display: none !important;
      }

      /* "Go to the original" */

      p.text-green-500.text-sm > a {
        display: none !important;
      }

      /* Tags section */

      div:has(> a[href*="/tag/"]) {
        display: none !important;
      }

      /* ================================
         Prevent horizontal overflow
         ================================ */

      body * {
        box-sizing: border-box !important;
      }

      p,
      div,
      section,
      article,
      main,
      aside {
        max-width: 100% !important;
      }
    ''';
  }

  static String _getGoogleFontUrl(String family) {
    final encodedFamily = Uri.encodeComponent(family).replaceAll('%20', '+');

    return 'https://fonts.googleapis.com/css2'
        '?family=$encodedFamily:wght@400;600;700'
        '&display=swap';
  }

  static String _getFallbackFont(String family) {
    switch (family.toLowerCase()) {
      case 'merriweather':
      case 'georgia':
      case 'lora':
      case 'source serif 4':
        return 'serif';

      default:
        return 'sans-serif';
    }
  }
}

class _ThemeColors {
  const _ThemeColors({
    required this.background,
    required this.text,
    required this.link,
    required this.codeBackground,
    required this.codeText,
    required this.quoteBorder,
    required this.quoteText,
    required this.border,
    required this.selection,
  });
  final String background;
  final String text;
  final String link;
  final String codeBackground;
  final String codeText;
  final String quoteBorder;
  final String quoteText;
  final String border;
  final String selection;
}

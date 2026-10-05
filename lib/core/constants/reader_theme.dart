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
  // Host mode and code colors
  // ---------------------------------------------------------------------------

  /// Tells the host page which mode the reader is in, then repairs any code
  /// color the page cannot fix on its own.
  ///
  /// Two separate problems surface once the reader replaces the page's own
  /// surface, and both need script rather than CSS:
  ///
  /// * A site that ships a light and a dark code palette gates the dark one
  ///   behind a switch on the root element -- a `dark` class, or a
  ///   `data-theme`-style attribute. The reader only ever set `color-scheme`,
  ///   which such sites ignore, so the page kept rendering its light palette.
  ///   The reader then painted its dark code surface behind near-black tokens,
  ///   which is unreadable.
  /// * A site that ships a single palette has no dark variant to switch to, so
  ///   its tokens stay tuned for the original surface no matter what the host is
  ///   told. This is the common case for Shiki, Pygments and Prism output.
  ///
  /// So the reader claims the switches sites use to advertise a dark UI, and
  /// then applies a contrast floor to code token spans. A token that already
  /// reads against the code surface keeps its color, so real syntax
  /// highlighting survives; only a genuinely illegible one is rewritten. An
  /// earlier version of this rule left every token alone, which meant a
  /// mismatched palette was the reader's problem to solve with a blanket
  /// `color` override -- and that in turn throws the highlighting away.
  ///
  /// The script carries no palette of its own. It reads the reader's
  /// `color-scheme` and each code surface's computed background, so one source
  /// serves every theme and a theme change is picked up by the next run.
  static const String hostModeSyncJs = '''
(function () {
  'use strict';

  /*
   * The legibility floor for a code token, as a contrast ratio. Kept in step
   * with the palette: a token below this against the code surface is not worth
   * preserving as syntax highlighting, and one above it is left alone.
   */
  var MIN_CONTRAST = 3;

  /* Coalesces the burst of mutations a single page load produces. */
  var DEBOUNCE = 200;

  /* Marks spans this script repainted, and the color they carried before. */
  var MARK = 'data-freedium-code-color';
  var SAVED = 'data-freedium-code-saved';

  /* The switches sites use to advertise a dark UI. */
  var DARK_CLASSES = ['dark', 'dark-mode'];
  var DARK_ATTRIBUTES = ['data-theme', 'data-color-mode'];

  /*
   * The stylesheet is re-injected on every settings change, and this script
   * installs observers. The flag keeps one set of them alive per document
   * while still letting every run re-apply the current theme.
   */
  var INSTALLED = '__freediumReaderSync';

  var timer = 0;
  var running = false;

  function parseColor(value) {
    /*
     * Only rgb() and rgba() are accepted. A color this cannot read is skipped
     * rather than guessed at, because a wrong guess would rewrite good
     * highlighting.
     */
    if (!value || value.indexOf('rgb') !== 0) return null;

    var parts = value.match(/[0-9.]+/g);
    if (!parts || parts.length < 3) return null;

    return {
      r: parseFloat(parts[0]),
      g: parseFloat(parts[1]),
      b: parseFloat(parts[2]),
      a: parts.length > 3 ? parseFloat(parts[3]) : 1
    };
  }

  /* Resolves a translucent surface against what shows through it. */
  function flatten(color, behind) {
    if (color.a >= 1) return color;

    return {
      r: color.r * color.a + behind.r * (1 - color.a),
      g: color.g * color.a + behind.g * (1 - color.a),
      b: color.b * color.a + behind.b * (1 - color.a),
      a: 1
    };
  }

  function channel(value) {
    var v = value / 255;
    return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
  }

  function luminance(color) {
    return (
      0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b)
    );
  }

  function contrast(a, b) {
    var la = luminance(a);
    var lb = luminance(b);

    return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
  }

  function isHidden(node) {
    while (node && node.nodeType === 1) {
      var style = getComputedStyle(node);
      if (style.display === 'none' || style.visibility === 'hidden') {
        return true;
      }

      node = node.parentElement;
    }

    return false;
  }

  function insidePre(node) {
    var parent = node.parentNode;

    while (parent && parent.nodeType === 1) {
      if (parent.nodeName === 'PRE') return true;
      parent = parent.parentNode;
    }

    return false;
  }

  /*
   * Puts back the colors saved by a previous run, so a theme change is
   * measured against the host's real palette rather than against a color this
   * script chose the last time round.
   */
  function restore() {
    var marked = document.querySelectorAll('[' + MARK + ']');

    for (var i = 0; i < marked.length; i++) {
      var el = marked[i];
      var saved = el.getAttribute(SAVED) || '';

      if (saved) {
        el.style.setProperty('color', saved, 'important');
      } else {
        el.style.removeProperty('color');
      }

      el.removeAttribute(SAVED);
      el.removeAttribute(MARK);
    }
  }

  function repairCodeColors() {
    restore();

    var blocks = document.querySelectorAll('pre, code');
    if (!blocks.length) return;

    /*
     * Inline code sits on a translucent surface, so it can only be judged once
     * that surface is resolved over the page behind it.
     */
    var page =
      parseColor(getComputedStyle(document.documentElement).backgroundColor) ||
      { r: 255, g: 255, b: 255, a: 1 };

    var pending = [];
    var i, j, node, style, spans, span, token, surface, fallback, keep, replace;
    var fallbackValue;

    /*
     * Read first and write second. Reading a computed style flushes layout and
     * setting a style invalidates it, so measuring and repainting in the same
     * pass would re-layout once per token in the block.
     */
    for (i = 0; i < blocks.length; i++) {
      node = blocks[i];

      /* Code inside a block is styled by that block, not by itself. */
      if (node.nodeName === 'CODE' && insidePre(node)) continue;
      if (isHidden(node)) continue;

      style = getComputedStyle(node);
      surface = parseColor(style.backgroundColor);

      /*
       * The code element's own color is the reader's code foreground, since the
       * reader forces it. It is both the yardstick a token is measured against
       * and the value an unreadable token is rewritten to, which keeps the
       * repair consistent with the active theme without carrying a palette.
       */
      fallbackValue = style.color;
      fallback = parseColor(fallbackValue);

      if (!surface || !fallback) continue;

      surface = flatten(surface, page);
      replace = contrast(fallback, surface);

      spans = node.querySelectorAll('span');
      for (j = 0; j < spans.length; j++) {
        span = spans[j];

        style = getComputedStyle(span);
        if (style.display === 'none' || style.visibility === 'hidden') continue;

        token = parseColor(style.color);
        if (!token) continue;

        keep = contrast(token, surface);

        /*
         * A palette that already reads is left alone. This is a legibility
         * floor, not a licence to restyle every highlighter on the web.
         */
        if (keep >= MIN_CONTRAST || replace <= keep) continue;

        pending.push({
          element: span,
          saved: span.style.getPropertyValue('color'),
          value: fallbackValue
        });
      }
    }

    for (i = 0; i < pending.length; i++) {
      pending[i].element.setAttribute(SAVED, pending[i].saved);
      pending[i].element.setAttribute(MARK, '');
      pending[i].element.style.setProperty(
        'color',
        pending[i].value,
        'important'
      );
    }
  }

  function readerIsDark() {
    var scheme = getComputedStyle(document.documentElement).colorScheme || '';

    if (scheme === 'dark') return true;
    if (scheme === 'light') return false;

    /* Only reached if the stylesheet has not been applied yet. */
    return !!(
      window.matchMedia &&
      window.matchMedia('(prefers-color-scheme: dark)').matches
    );
  }

  function syncHostMode() {
    var dark = readerIsDark();
    var scheme = dark ? 'dark' : 'light';
    var root = document.documentElement;
    var i, name, present;

    for (i = 0; i < DARK_CLASSES.length; i++) {
      name = DARK_CLASSES[i];
      present = root.classList.contains(name);

      if (dark && !present) root.classList.add(name);
      else if (!dark && present) root.classList.remove(name);
    }

    for (i = 0; i < DARK_ATTRIBUTES.length; i++) {
      name = DARK_ATTRIBUTES[i];

      if (root.getAttribute(name) !== scheme) {
        root.setAttribute(name, scheme);
      }
    }

    /*
     * Theme watchers write this inline, where it outranks any stylesheet rule,
     * so the reader has to claim it too or the page decides the mode again.
     */
    if (root.style.colorScheme !== scheme) {
      root.style.colorScheme = scheme;
    }
  }

  function hostModeDrifted() {
    var dark = readerIsDark();
    var scheme = dark ? 'dark' : 'light';
    var root = document.documentElement;
    var i;

    for (i = 0; i < DARK_CLASSES.length; i++) {
      if (root.classList.contains(DARK_CLASSES[i]) !== dark) return true;
    }

    for (i = 0; i < DARK_ATTRIBUTES.length; i++) {
      if (root.getAttribute(DARK_ATTRIBUTES[i]) !== scheme) return true;
    }

    return root.style.colorScheme !== scheme;
  }

  function apply() {
    timer = 0;
    if (running) return;

    running = true;

    try {
      syncHostMode();
      repairCodeColors();
    } catch (err) {
      /* A reader must never take the page down with it. */
    }

    running = false;
  }

  function schedule() {
    if (timer) clearTimeout(timer);
    timer = setTimeout(apply, DEBOUNCE);
  }

  /*
   * Runs after the stylesheet has been appended, so `color-scheme` is already
   * readable and an explicit theme is never second-guessed by the platform.
   */
  apply();

  if (window[INSTALLED]) return;
  window[INSTALLED] = true;

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', schedule);
  }

  window.addEventListener('load', schedule);

  /*
   * Only the root element's own attributes are watched, and only so a theme
   * watcher cannot take the page's mode back after the reader set it.
   *
   * Deliberately not a `subtree` observer. Code blocks do arrive after load —
   * rendered lazily, or restored from the back/forward cache — and repairing
   * them was the reason this used to watch the whole document. But that made
   * the reader a participant in page load: a `subtree` observer fires on every
   * mutation, and this callback's `querySelector` plus the style reads in
   * repairCodeColors turn each one into a layout flush, so on a page that is
   * still hydrating the main thread is saturated and a scroll gesture never
   * gets processed. The reader appeared not to scroll at all until the page was
   * reloaded and stopped mutating.
   *
   * Late code is repaired by the reader instead: [injectCssScript] runs again on
   * load and on every settings change, and each run calls `apply()` above.
   */
  if (window.MutationObserver) {
    new MutationObserver(function () {
      if (hostModeDrifted()) schedule();
    }).observe(document.documentElement, {
      attributes: true,
      attributeFilter: ['class', 'style'].concat(DARK_ATTRIBUTES)
    });
  }
})();
''';

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
$hostModeSyncJs
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

  /*
   * Bounded passes rather than a `subtree` MutationObserver.
   *
   * Observing the whole document looks like the robust way to catch a paywall
   * that renders late, but it makes the reader a participant in page load: every
   * mutation anywhere fires the callback, and `stripPopups` runs a twelve-branch
   * `querySelectorAll` across the entire document each time. On a page still
   * hydrating that saturates the main thread, and a scroll gesture competes with
   * it for the same thread and loses -- the reader looked frozen until the page
   * was reloaded and stopped mutating.
   *
   * A popup that exists is caught instead by the `load` pass and the one deferred
   * past it, which is where hydration-driven dialogs actually appear.
   */
  document.addEventListener(
    'DOMContentLoaded',
    function () {
      setTimeout(function () {
        hydrationReady = true;
        stripPopups();
      }, 350);
    },
  );

  document.addEventListener('load', function () {
    stripPopups();
    setTimeout(stripPopups, 600);
  });

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
  // Offline capture
  // ---------------------------------------------------------------------------

  /// Clones the article's markup for the offline cache.
  ///
  /// Scripts, styles and the reader's own injected stylesheet are removed: none
  /// of them are content, the reader re-applies its own styling when the cached
  /// copy is rendered, and a page's own stylesheet is what makes its raw
  /// markup unreadable in the first place. Images are kept so an article that
  /// is re-read with a connection still shows its figures; without one they
  /// simply fail to load.
  ///
  /// Returns a JSON string (not an object) so the result survives
  /// `evaluateJavascript`, which stringifies its return value.
  static const String extractArticleHtmlJs = '''
(function() {
  var root =
    document.querySelector('article') ||
    document.querySelector('main') ||
    document.body;

  if (!root) return JSON.stringify({ html: '', found: false });

  var clone = root.cloneNode(true);

  var unwanted = clone.querySelectorAll(
    'script, style, noscript, link, iframe[src*="javascript"], ' +
      '#custom-reader-style, #freedium-early-flash-prevention'
  );

  for (var i = 0; i < unwanted.length; i++) {
    if (unwanted[i].parentNode) unwanted[i].parentNode.removeChild(unwanted[i]);
  }

  return JSON.stringify({ html: clone.outerHTML, found: true });
})();
''';

  // ---------------------------------------------------------------------------
  // Scroll diagnostics
  // ---------------------------------------------------------------------------

  /// Reports everything a "the page will not scroll" report turns on.
  ///
  /// A WebView that refuses to scroll reports nothing to the app: no callback,
  /// no error, no visual change. The only way to tell a document that cannot
  /// scroll from a document whose scroll gesture never arrived is to ask the
  /// document, so this answers the questions that distinguish them:
  ///
  ///  * is the content taller than the viewport, and by how much
  ///  * which element is the scroller, and how far is it scrolled
  ///  * what the root and body compute to, since a root pinned to the viewport
  ///    is the single most common reason a page that looks scrollable is not
  ///
  /// Wrapped so a document that throws reports `error` instead of taking the
  /// channel down with it.
  static const String scrollDiagnosticsJs = '''
(function() {
  try {
    var doc = document.documentElement;
    var body = document.body;

    var viewport = window.innerHeight || 0;
    var docHeight = doc ? doc.scrollHeight : 0;
    var bodyHeight = body ? body.scrollHeight : 0;
    var contentHeight = Math.max(docHeight, bodyHeight);

    var scrollingElement = document.scrollingElement || doc;

    // Named separately from the document, because a host shell that keeps its
    // own scroll container scrolls an inner element and leaves the document
    // reporting a permanently unchanging zero.
    var scroller = 'none';
    var candidates = [doc, body].concat(
      Array.prototype.slice.call(
        document.querySelectorAll(
          'div[style*="overflow-y"], div[style*="overflow: auto"], ' +
            'div[style*="overflow: scroll"]'
        )
      )
    );

    for (var i = 0; i < candidates.length; i++) {
      var node = candidates[i];

      if (node && node.scrollHeight - node.clientHeight > 8) {
        scroller = {
          tagName: node.tagName ? node.tagName.toLowerCase() : '',
          id: node.id || '',
          className: typeof node.className === 'string' ? node.className : '',
          scrollHeight: node.scrollHeight,
          clientHeight: node.clientHeight,
          scrollTop: node.scrollTop
        };
        break;
      }
    }

    function styleOf(node) {
      if (!node) return null;

      var computed = getComputedStyle(node);

      return {
        overflowY: computed.overflowY,
        overflowX: computed.overflowX,
        height: computed.height,
        minHeight: computed.minHeight,
        maxHeight: computed.maxHeight,
        position: computed.position,
        touchAction: computed.touchAction
      };
    }

    var visual = window.visualViewport;

    return JSON.stringify({
      contentHeight: contentHeight,
      viewport: viewport,
      contentTallerThanViewport: contentHeight > viewport,
      scrollingElement: scrollingElement ? scrollingElement.tagName : null,
      scrollY: window.pageYOffset,
      docStyle: styleOf(doc),
      htmlStyle: styleOf(doc),
      bodyStyle: styleOf(body),
      scroller: scroller,
      visualViewport: visual
        ? { height: visual.height, scale: visual.scale }
        : null
    });
  } catch (e) {
    return JSON.stringify({ error: String(e) });
  }
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
  /// Runs [hostModeSyncJs] afterwards, so a theme change re-claims the host's
  /// dark-mode switch and re-measures code colors against the new palette.
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

    // Force a layout recalculation to ensure scroll settings take effect
    // on first load. Without this, the WebView may not recognize the new
    // overflow/height settings until a refresh forces a re-layout.
    void document.body.offsetHeight;
  } catch (e) {}
})();
$hostModeSyncJs
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
        /*
         * `!important` because hostModeSyncJs reads this value to decide which
         * dark palette to ask the page for. A page that also sets
         * `color-scheme` would otherwise win the tie and take the mode back.
         */
        color-scheme: ${isDark ? 'dark' : 'light'} !important;
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

        /*
         * The root has to be the thing that scrolls, and the only way to
         * guarantee that is to take the decision away from the host page.
         *
         * The mirror serves the publisher's real desktop layout, whose shell
         * pins `html`/`body` to the height of the viewport and hides the
         * overflow, then scrolls an inner container instead. A document pinned
         * to the viewport is exactly `viewport` tall, so there is nothing for a
         * drag to move: the article is present, taller than the screen, and
         * the page will not scroll no matter how far the reader pulls. Only
         * `min-height` is set above, so nothing overrode the host's `height`
         * and the pin survived.
         */
        height: auto !important;
        overflow: visible !important;
        position: static !important;
      }

      body {
        margin: 0 !important;
        padding: ${m.gutter}px !important;

        width: 100% !important;
        max-width: 100% !important;
        min-height: 100vh !important;

        /* The counterpart of the root rule above: the same pin, one level down. */
        height: auto !important;
        max-height: none !important;
        overflow: visible !important;
        position: static !important;

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

        /* The article is a page, not a panel: a pinned height here is the same
         * dead end as one on the root, one level in. */
        height: auto !important;
        max-height: none !important;
      }

      /*
       * The host shell's scroll container, unwound.
       *
       * Matched on the inline style it pins itself with, and scoped to the
       * article: a rule that reset every descendant would flatten the code
       * blocks and figures the reader does want laid out as they are, and a rule
       * that guessed at `overflow` in general would do the same.
       */
      article div[style*="100vh"],
      article div[style*="100%"],
      article main[style*="100vh"],
      article main[style*="100%"],
      article section[style*="100vh"],
      article section[style*="100%"] {
        height: auto !important;
        max-height: none !important;
        overflow: visible !important;
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
       * their colors alone: those colors are the syntax highlighting, and a
       * blanket override here would throw it away. A palette that does not
       * read against this surface is repaired by hostModeSyncJs instead, which
       * can tell a mismatched token from a deliberately dim one.
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

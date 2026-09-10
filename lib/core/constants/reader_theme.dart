class ReaderTheme {
  ReaderTheme._();

  static const String customCssId = 'custom-reader-style';

  static const _light = _ThemeColors(
    background: '#fdfcff',
    text: '#1a1c1e',
    link: '#005cbb',
    codeBackground: '#f0f0f0',
    codeText: '#333333',
    quoteBorder: '#005cbb',
    quoteText: '#546e7a',
  );

  static const _dark = _ThemeColors(
    background: '#1a1c1e',
    text: '#e2e2e6',
    link: '#aec6ff',
    codeBackground: '#2c2c2c',
    codeText: '#e0e0e0',
    quoteBorder: '#64b5f6',
    quoteText: '#b0bec5',
  );

  static String getCss({
    required double fontSize,
    required bool isDarkMode,
    String fontFamily = 'Inter',
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
        line-height: 1.6 !important;

        -webkit-font-smoothing: antialiased !important;
        text-rendering: optimizeLegibility !important;
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
      body blockquote {
        font-family: inherit !important;
        color: inherit !important;
      }

      p {
        margin: 0 0 1em !important;
      }

      h1,
      h2,
      h3,
      h4,
      h5,
      h6 {
        margin-top: 1.5em !important;
        margin-bottom: 0.5em !important;

        font-family: inherit !important;
        font-weight: 600 !important;
        line-height: 1.3 !important;
        color: inherit !important;
      }

      h1 {
        font-size: 2em !important;
      }

      h2 {
        font-size: 1.5em !important;
      }

      h3 {
        font-size: 1.25em !important;
      }

      h4 {
        font-size: 1.1em !important;
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
      }

      a:hover {
        text-decoration: underline !important;
      }

      /* ================================
         Blockquotes
         ================================ */

      blockquote {
        margin: 16px 0 !important;
        padding: 4px 0 4px 16px !important;

        border-left: 4px solid ${colors.quoteBorder} !important;

        color: ${colors.quoteText} !important;
        font-style: italic !important;
      }

      /* ================================
         Code
         ================================ */

      code {
        padding: 2px 5px !important;
        border-radius: 4px !important;

        background: ${colors.codeBackground} !important;
        color: ${colors.codeText} !important;

        font-family:
          'SFMono-Regular',
          Consolas,
          'Liberation Mono',
          Menlo,
          monospace !important;

        font-size: 0.9em !important;
      }

      pre {
        margin: 16px 0 !important;
        padding: 12px !important;

        max-width: 100% !important;
        overflow-x: auto !important;
        white-space: pre-wrap !important;
        overflow-wrap: anywhere !important;

        border-radius: 6px !important;

        background: ${colors.codeBackground} !important;
        color: ${colors.codeText} !important;

        font-family:
          'SFMono-Regular',
          Consolas,
          'Liberation Mono',
          Menlo,
          monospace !important;

        line-height: 1.5 !important;
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

      iframe {
        border: 0 !important;
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
      nav,
      header,
      .navbar,
      #darkModeToggle,
      #openProblemModal,
      .storage-notification-container,
      .fixed.bottom-4.left-4 {
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
  });
  final String background;
  final String text;
  final String link;
  final String codeBackground;
  final String codeText;
  final String quoteBorder;
  final String quoteText;
}

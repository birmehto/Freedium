import 'dart:convert';

import '../../../../core/utils/app_log.dart';
import 'medium_profile.dart';

/// Turns what a Medium profile page shows into a [MediumProfile].
///
/// The injected script deliberately reports raw strings and leaves every
/// interpretation here, so the fragile parts — compact counts like `1.2K`,
/// `Name on Medium` suffixes, `@handle` normalization — stay unit-testable
/// without a WebView.
abstract final class MediumProfileParser {
  /// JavaScript that collects candidate profile fields from the loaded document.
  ///
  /// Every field is optional: Medium ships markup changes often, and the same
  /// script runs on a page that may be signed out, blocked or only
  /// half-rendered.
  ///
  /// Prefers the Open Graph tags, which Medium fills in server-side and treats
  /// as a stable contract, and falls back to the rendered profile header for
  /// the engagement counts, which have no metadata equivalent.
  static const String extractScript = '''
(function () {
  var content = function (selector) {
    var el = document.querySelector(selector);
    return el ? (el.getAttribute('content') || '').trim() : '';
  };

  var text = function (selector) {
    var el = document.querySelector(selector);
    return el ? (el.textContent || '').trim() : '';
  };

  // Counts are rendered as "1.2K Followers" inside an anchor, so the label is
  // matched against short text nodes instead of a selector that Medium is free
  // to rename. First match wins because the header precedes the rest of page.
  var labelled = function (label) {
    var nodes = document.querySelectorAll('a, span, p, div');
    for (var i = 0; i < nodes.length; i++) {
      var value = (nodes[i].textContent || '').trim();
      if (value.length > 0 && value.length < 40 &&
          value.toLowerCase().indexOf(label) !== -1) {
        return value;
      }
    }
    return '';
  };

  // The handle, most reliable source first: a canonical or og:url link is
  // server-rendered, the /me URL is not (it carries no handle), and the
  // header avatar link is the last resort.
  var handleFrom = function (value) {
    var match = /@([A-Za-z0-9._-]+)/.exec(value || '');
    return match ? match[1] : '';
  };

  var header = document.querySelector('a[href^="/@"]');
  var handle = handleFrom(content('link[rel="canonical"]')) ||
      handleFrom(content('meta[property="og:url"]')) ||
      handleFrom(window.location.href) ||
      handleFrom(header ? header.getAttribute('href') : '');

  return JSON.stringify({
    handle: handle,
    title: content('meta[property="og:title"]') || text('h1'),
    description: content('meta[property="og:description"]'),
    image: content('meta[property="og:image"]'),
    followers: labelled('follower'),
    publications: labelled('post') || labelled('stor')
  });
})();
''';

  /// Bio copy that is really site boilerplate rather than anything the author
  /// wrote, so it never reaches the profile card.
  static const List<String> boilerplateBios = [
    'Read free articles',
    'Where good ideas find you',
    'Medium is a place',
    'Get the Medium app',
  ];

  /// Parses the JSON string produced by [extractScript].
  ///
  /// Returns `null` when the payload is unusable or carries no handle, which is
  /// the single signal that this is not the reader's own Medium profile.
  static MediumProfile? fromJsonString(String? raw) {
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;

      return fromJson(Map<String, dynamic>.from(decoded));
    } catch (error) {
      appLog(
        'Could not decode profile payload: $error',
        name: 'Account',
        level: LogLevel.warning,
      );
      return null;
    }
  }

  /// Builds a profile from the scraped fields, or `null` when there is no
  /// handle to build one from.
  static MediumProfile? fromJson(Map<String, dynamic> json) {
    final handle = _handle(json['handle'] as String?);
    if (handle.isEmpty) return null;

    final name = _name(json['title'] as String?, handle);
    final bio = _bio(json['description'] as String?);
    final avatarUrl = _url(json['image'] as String?);

    return MediumProfile(
      handle: handle,
      name: name,
      bio: bio,
      avatarUrl: avatarUrl,
      followerCount: parseCount(json['followers'] as String?),
      publicationCount: parseCount(json['publications'] as String?),
    );
  }

  /// `"1.2K"` becomes 1200 and `"1,234"` becomes 1234.
  ///
  /// Returns `null` when there is no number to read, which is how a count
  /// Medium chose not to render is represented.
  static int? parseCount(String? raw) {
    if (raw == null) return null;

    final match = _countPattern.firstMatch(raw);
    if (match == null) return null;

    final digits = match.group(1)!.replaceAll(',', '').replaceAll(' ', '');
    final value = double.tryParse(digits);
    if (value == null) return null;

    final multiplier = switch (match.group(2)?.toUpperCase()) {
      'K' => 1000,
      'M' => 1000000,
      'B' => 1000000000,
      _ => 1,
    };

    return (value * multiplier).round();
  }

  /// `1.2K`, `1,234 Followers`, `12.3M posts`.
  static final RegExp _countPattern = RegExp(
    r'([0-9][0-9.,]*)\s*([KMB])?',
    caseSensitive: false,
  );

  /// The handle, stripped of the leading `@` and of any path that followed it.
  static String _handle(String? raw) {
    if (raw == null) return '';
    return raw.trim().replaceFirst(RegExp('^@'), '').trim();
  }

  /// Medium titles a profile `"Jane Doe on Medium"`; the suffix is not a name.
  static String _name(String? raw, String handle) {
    if (raw == null) return handle;

    final trimmed = raw.trim();
    if (trimmed.isEmpty) return handle;

    // A title that is nothing but the suffix leaves the handle as the best
    // available name.
    if (_bareTitleSuffix.hasMatch(trimmed)) return handle;

    return trimmed.replaceFirst(_titleSuffix, '').trim();
  }

  static final RegExp _titleSuffix = RegExp(
    r'\s+on\s+Medium$',
    caseSensitive: false,
  );

  static final RegExp _bareTitleSuffix = RegExp(
    r'^on\s+Medium$',
    caseSensitive: false,
  );

  /// The bio, unless it is site boilerplate or empty.
  static String? _bio(String? raw) {
    if (raw == null) return null;

    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    for (final phrase in boilerplateBios) {
      if (trimmed.toLowerCase().contains(phrase.toLowerCase())) return null;
    }

    return trimmed;
  }

  /// An absolute http(s) URL, or `null` for a relative or unusable value.
  static String? _url(String? raw) {
    if (raw == null) return null;

    final trimmed = raw.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;

    return trimmed;
  }
}

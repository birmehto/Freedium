/// The Medium web session that keeps a reader signed in between launches.
///
/// Medium has no public API for this, so a session is just the set of cookies
/// its own website sets when a reader signs in. They are re-injected into the
/// WebView cookie jar on the next launch, which is what makes the account
/// survive without the app ever seeing a password.
///
/// This is the one place in the app that holds a credential, so it is kept
/// deliberately narrow: only cookies the session needs are kept, and they are
/// never logged.
class MediumSession {
  MediumSession(Map<String, String> cookies)
    : cookies = Map<String, String>.unmodifiable(cookies);

  /// Builds a session from a raw cookie jar, dropping [ignoredCookies] and
  /// blank values.
  factory MediumSession.fromCookiePairs(List<Map<String, String>> pairs) {
    final kept = <String, String>{};

    for (final pair in pairs) {
      // Each entry is a single cookie, so anything else is not a cookie jar
      // this store produced and is skipped rather than half-read.
      if (pair.length != 1) continue;

      final name = pair.keys.first;
      final value = pair[name] ?? '';

      if (name.isEmpty || value.isEmpty) continue;
      if (ignoredCookies.contains(name)) continue;

      kept[name] = value;
    }

    return MediumSession(kept);
  }

  factory MediumSession.fromJson(Map<String, dynamic> json) {
    final raw = json['cookies'];
    if (raw is! Map) return MediumSession(const {});

    return MediumSession({
      for (final entry in raw.entries)
        if (entry.key is String && entry.value != null)
          entry.key as String: '${entry.value}',
    });
  }

  /// The origin every Medium session cookie is scoped to.
  static const String origin = 'https://medium.com';

  /// The cookie domain Medium issues its session cookies on.
  static const String domain = '.medium.com';

  /// Cookies whose presence proves a Medium session exists.
  ///
  /// Medium sets at least one of these on sign-in; anonymous visitors get
  /// analytics cookies only, which is why a session is not treated as valid
  /// without one of them.
  static const Set<String> authenticatingCookies = {'sid', 'uid', 'token'};

  /// Never persisted.
  ///
  /// Analytics and advertising cookies say nothing about the session, so
  /// keeping them would widen the stored footprint for no benefit.
  static const Set<String> ignoredCookies = {
    '_ga',
    '_gid',
    '__gads',
    '_gcl_au',
    '__s',
    'amplitude',
    'amp',
    '__amp_source',
    '__hmpl',
    '__hstc',
    '__ssr_prestart',
    'eu_cookie',
    'medium_evergreen_cookie_consent',
  };

  /// Cookie name/value pairs, excluding [ignoredCookies].
  final Map<String, String> cookies;

  /// The cookies as single-entry maps: the shape a cookie jar is read and
  /// written in.
  List<Map<String, String>> get cookiePairs => [
    for (final entry in cookies.entries) {entry.key: entry.value},
  ];

  /// Whether these cookies represent a real, signed-in session.
  bool get isAuthenticated => cookies.keys.any(authenticatingCookies.contains);

  Map<String, dynamic> toJson() => {'cookies': cookies};
}

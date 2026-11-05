import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../utils/app_log.dart';

/// The slice of cookie storage the account feature needs.
///
/// Declared as an interface so [AuthService] can be exercised without a
/// platform channel: the session rules are the part worth testing, and they
/// should not require a WebView to reach.
abstract interface class CookieStore {
  /// Every cookie currently held for [url], as single-entry name/value maps.
  Future<List<Map<String, String>>> read(String url);

  /// Writes [cookies] for [url], scoped to [domain] when one is given.
  Future<void> write(
    String url,
    List<Map<String, String>> cookies, {
    String? domain,
  });

  /// Deletes the named cookies for [url].
  Future<void> remove(String url, Iterable<String> names, {String? domain});
}

/// [CookieStore] backed by the WebView's cookie jar.
///
/// The jar is shared by every `InAppWebView` in the process, which is what lets
/// the sign-in screen hand a live session to the profile screen without either
/// of them owning a cookie.
class WebViewCookieStore implements CookieStore {
  const WebViewCookieStore();

  @override
  Future<List<Map<String, String>>> read(String url) async {
    try {
      final cookies = await CookieManager.instance().getCookies(
        url: WebUri(url),
      );

      return [
        for (final cookie in cookies)
          if (cookie.value != null) {cookie.name: '${cookie.value}'},
      ];
    } catch (error) {
      appLog(
        'Could not read cookies: $error',
        name: 'Account',
        level: LogLevel.warning,
      );
      return const [];
    }
  }

  @override
  Future<void> write(
    String url,
    List<Map<String, String>> cookies, {
    String? domain,
  }) async {
    for (final cookie in cookies) {
      try {
        await CookieManager.instance().setCookie(
          url: WebUri(url),
          name: cookie.keys.first,
          value: cookie.values.first,
          domain: domain,
        );
      } catch (error) {
        appLog(
          'Could not restore cookie "${cookie.keys.first}": $error',
          name: 'Account',
          level: LogLevel.warning,
        );
      }
    }
  }

  @override
  Future<void> remove(
    String url,
    Iterable<String> names, {
    String? domain,
  }) async {
    for (final name in names) {
      try {
        await CookieManager.instance().deleteCookie(
          url: WebUri(url),
          name: name,
          domain: domain,
        );
      } catch (error) {
        appLog(
          'Could not clear cookie: $error',
          name: 'Account',
          level: LogLevel.warning,
        );
      }
    }
  }
}

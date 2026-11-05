import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/features/account/controllers/login_controller.dart';

import '../../helpers/test_env.dart';

void main() {
  group('LoginController entry points', () {
    test('signs in on the route Medium actually serves', () {
      // `/login` now only redirects to `/m/signin`, so asking for it directly
      // would spend a round trip on every attempt.
      expect(
        LoginController.signInUrl,
        startsWith('https://medium.com/m/signin'),
      );
    });

    test('asks Medium to land the reader on their profile after sign-in', () {
      expect(LoginController.signInUrl, contains('redirect='));
      expect(
        Uri.parse(LoginController.signInUrl).queryParameters['redirect'],
        'https://medium.com/me',
      );
    });

    test('refreshes through the same profile route the redirect targets', () {
      expect(LoginController.profileUrl, 'https://medium.com/me');
      expect(LoginController.isProfilePage(LoginController.profileUrl), isTrue);
    });
  });

  group('LoginController.isProfilePage', () {
    test('recognises the own-profile page', () {
      expect(LoginController.isProfilePage('https://medium.com/me'), isTrue);
    });

    test('ignores the query string and trailing slash Medium adds', () {
      expect(LoginController.isProfilePage('https://medium.com/me/'), isTrue);
      expect(
        LoginController.isProfilePage('https://medium.com/me?source=nav'),
        isTrue,
      );
      expect(
        LoginController.isProfilePage('https://medium.com/me/#posts'),
        isTrue,
      );
    });

    test('does not mistake a member profile for the reader', () {
      expect(
        LoginController.isProfilePage('https://medium.com/@someone'),
        isFalse,
      );
      expect(LoginController.isProfilePage('https://medium.com/'), isFalse);
      expect(LoginController.isProfilePage(LoginController.signInUrl), isFalse);
    });

    test('handles an empty or unparseable URL', () {
      expect(LoginController.isProfilePage(''), isFalse);
      expect(LoginController.isProfilePage('not a url'), isFalse);
    });
  });

  group('LoginController.isAllowedAuthHost', () {
    test('allows Medium and the identity providers it offers', () {
      expect(LoginController.isAllowedAuthHost('medium.com'), isTrue);
      expect(LoginController.isAllowedAuthHost('google.com'), isTrue);
      expect(LoginController.isAllowedAuthHost('accounts.google.com'), isTrue);
    });

    test('allows the YouTube hop Google makes while signing in on Medium', () {
      // Medium's Google sign-in moves the session through
      // accounts.youtube.com/accounts/SetSID. Blocking it strands the flow.
      expect(LoginController.isAllowedAuthHost('accounts.youtube.com'), isTrue);
    });

    test('keeps the YouTube entry narrow', () {
      // Only the accounts host is part of the flow, so the entry must not open
      // the rest of YouTube up to navigation.
      expect(LoginController.isAllowedAuthHost('www.youtube.com'), isFalse);
      expect(LoginController.isAllowedAuthHost('youtube.com'), isFalse);
    });

    test('is case and whitespace insensitive', () {
      expect(LoginController.isAllowedAuthHost('  Medium.COM '), isTrue);
    });

    test('rejects lookalike hosts', () {
      expect(LoginController.isAllowedAuthHost('notmedium.com'), isFalse);
      expect(
        LoginController.isAllowedAuthHost('medium.com.evil.test'),
        isFalse,
      );
      expect(LoginController.isAllowedAuthHost('evil.test'), isFalse);
    });
  });

  group('LoginController navigation policy', () {
    late LoginController controller;

    setUp(() {
      controller = LoginController(MemoryCookieStore());
    });

    tearDown(() {
      controller.dispose();
    });

    test('cancels a null navigation', () {
      expect(controller.resolveNavigation(null), NavigationActionPolicy.CANCEL);
    });

    test('cancels a custom scheme', () {
      expect(
        controller.resolveNavigation(
          WebUri('intent://scan#Intent;scheme=zxing'),
        ),
        NavigationActionPolicy.CANCEL,
      );
    });

    test('allows an in-flow main frame', () {
      expect(
        controller.resolveNavigation(WebUri(LoginController.signInUrl)),
        NavigationActionPolicy.ALLOW,
      );
    });

    test('cancels a main frame that leaves the flow', () {
      expect(
        controller.resolveNavigation(WebUri('https://evil.test/steal')),
        NavigationActionPolicy.CANCEL,
      );
    });

    test('allows the whole Google sign-in chain, YouTube hop included', () {
      const chain = [
        'https://accounts.google.com/o/oauth2/auth',
        'https://accounts.google.com/signin/oauth/consent',
        'https://accounts.youtube.com/accounts/SetSID?ssdc=1&continue=x',
        'https://consent.google.com/m',
        'https://medium.com/m/signin',
      ];

      for (final url in chain) {
        expect(
          controller.resolveNavigation(WebUri(url)),
          NavigationActionPolicy.ALLOW,
          reason: '$url must stay inside the sign-in flow',
        );
      }
    });

    test('allows a subframe wherever it points', () {
      // An embedded captcha or OAuth card belongs to the flow even though it is
      // served from somewhere else entirely.
      expect(
        controller.resolveNavigation(
          WebUri('https://challenges.cloudflare.com/turnstile'),
          isMainFrame: false,
        ),
        NavigationActionPolicy.ALLOW,
      );
    });
  });
}

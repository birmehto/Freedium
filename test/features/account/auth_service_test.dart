import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/routes/app_routes.dart';
import 'package:freedium/core/services/auth_service.dart';
import 'package:freedium/core/services/storage_service.dart';
import 'package:freedium/features/account/models/medium_profile.dart';
import 'package:freedium/features/account/models/medium_session.dart';
import 'package:get/get.dart';

import '../../helpers/test_env.dart';

/// Stands in for the sign-in screen, closing with [profile] — or with nothing,
/// which is what a reader who backs out produces.
class FakeLoginPage extends StatelessWidget {
  const FakeLoginPage({super.key, this.profile});

  final MediumProfile? profile;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.back<MediumProfile>(result: profile);
    });

    return const Scaffold(body: SizedBox.shrink());
  }
}

Widget loginApp() {
  return GetMaterialApp(
    initialRoute: AppRoutes.home,
    getPages: [
      GetPage(name: AppRoutes.home, page: () => const Scaffold()),
      GetPage(
        name: AppRoutes.login,
        page: () => FakeLoginPage(profile: _nextResult),
      ),
    ],
  );
}

/// Awaits [action] while pumping frames.
///
/// A GetX navigation future only completes once the pushed route has been built
/// and popped, so awaiting it from a test body without pumping in between would
/// deadlock.
Future<void> pumpAction(
  WidgetTester tester,
  Future<void> Function() action,
) async {
  final pending = action();

  await tester.pump();
  await tester.pump();
  await tester.pumpAndSettle();
  await pending;
}

/// The profile the next [FakeLoginPage] closes with; `null` means the reader
/// backed out without signing in.
MediumProfile? _nextResult;

const jane = MediumProfile(
  handle: 'janedoe',
  name: 'Jane Doe',
  bio: 'Writing about design systems.',
  followerCount: 1200,
  publicationCount: 42,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late MemoryCookieStore jar;
  late AuthService auth;

  setUp(() {
    final services = registerServices();
    storage = services.storage;
    jar = services.cookies;
    auth = services.auth;
    _nextResult = null;
  });

  group('AuthService.init', () {
    test('starts signed out with nothing saved', () async {
      await auth.init();

      expect(auth.isSignedIn, isFalse);
      expect(auth.user.value, isNull);
      expect(auth.handle, isEmpty);
      expect(jar.writes, isEmpty);
    });

    test('re-seeds the cookie jar from a saved session', () async {
      await storage.account.saveSession(MediumSession(const {'sid': 'abc'}));

      await auth.init();

      expect(jar.writes, hasLength(1));
      expect(jar.writes.single.$1, MediumSession.origin);
      expect(jar.writes.single.$2, [
        {'sid': 'abc'},
      ]);
      expect(jar.writes.single.$3, MediumSession.domain);
    });

    test('publishes the cached profile immediately', () async {
      await storage.account.saveSession(MediumSession(const {'sid': 'abc'}));
      await storage.account.saveProfile(jane);

      await auth.init();

      expect(auth.isSignedIn, isTrue);
      expect(auth.user.value, jane);
      expect(auth.handle, 'janedoe');
    });

    test(
      'a session with no cached profile is not treated as signed in',
      () async {
        await storage.account.saveSession(MediumSession(const {'sid': 'abc'}));

        await auth.init();

        expect(
          auth.isSignedIn,
          isFalse,
          reason: 'a session with nothing to show is not a signed-in reader',
        );
      },
    );

    test('a cached profile with no session is ignored', () async {
      await storage.account.saveProfile(jane);

      await auth.init();

      expect(auth.isSignedIn, isFalse);
    });
  });

  group('AuthService.captureSession', () {
    test('returns null for an empty jar', () async {
      expect(await auth.captureSession(), isNull);
    });

    test('keeps only session cookies from the live jar', () async {
      jar.pairs.addAll([
        {'sid': 'abc'},
        {'uid': '7'},
        {'_ga': 'GA1.2'},
      ]);

      final session = await auth.captureSession();

      expect(session?.cookies, {'sid': 'abc', 'uid': '7'});
      expect(session?.isAuthenticated, isTrue);
    });
  });

  group('AuthService.signOut', () {
    test(
      'clears cookies, the saved account and the published profile',
      () async {
        jar.pairs.add({'sid': 'abc'});
        await storage.account.saveSession(MediumSession(const {'sid': 'abc'}));
        await storage.account.saveProfile(jane);
        await auth.init();

        expect(auth.isSignedIn, isTrue);

        await auth.signOut();

        expect(auth.isSignedIn, isFalse);
        expect(auth.user.value, isNull);
        expect(jar.removed, ['sid']);
        expect(storage.account.session, isNull);
        expect(storage.account.profile, isNull);
      },
    );

    test('is harmless when nobody is signed in', () async {
      await auth.signOut();

      expect(auth.isSignedIn, isFalse);
      expect(jar.removed, isEmpty);
    });
  });

  group('AuthService.signIn', () {
    testWidgets('saves the session and profile the screen returned', (
      tester,
    ) async {
      jar.pairs.addAll([
        {'sid': 'abc'},
        {'_ga': 'GA1.2'},
      ]);
      _nextResult = jane;

      await tester.pumpWidget(loginApp());
      await pumpAction(tester, auth.signIn);

      expect(auth.isSignedIn, isTrue);
      expect(auth.user.value, jane);
      expect(storage.account.profile, jane);
      expect(storage.account.session?.cookies, {'sid': 'abc'});
    });

    testWidgets('leaves the reader signed out when the screen is dismissed', (
      tester,
    ) async {
      jar.pairs.add({'sid': 'abc'});
      _nextResult = null;

      await tester.pumpWidget(loginApp());
      await pumpAction(tester, auth.signIn);

      expect(auth.isSignedIn, isFalse);
      expect(
        storage.account.session,
        isNull,
        reason: 'a dismissed screen must not persist a half-finished account',
      );
    });

    testWidgets('keeps the profile for this session when cookies are missing', (
      tester,
    ) async {
      _nextResult = jane;

      await tester.pumpWidget(loginApp());
      await pumpAction(tester, auth.signIn);

      expect(auth.user.value, jane);
      expect(
        storage.account.session,
        isNull,
        reason: 'a profile that cannot be restored must not be saved as one',
      );
    });
  });

  group('AuthService.refreshProfile', () {
    testWidgets('replaces the cached profile', (tester) async {
      jar.pairs.add({'sid': 'abc'});
      await storage.account.saveSession(MediumSession(const {'sid': 'abc'}));
      await storage.account.saveProfile(jane);
      await auth.init();

      _nextResult = jane.copyWith(followerCount: 9999);

      await tester.pumpWidget(loginApp());
      late final bool refreshed;
      await pumpAction(
        tester,
        () async => refreshed = await auth.refreshProfile(),
      );

      expect(refreshed, isTrue);
      expect(auth.user.value?.followerCount, 9999);
      expect(storage.account.profile?.followerCount, 9999);
    });

    testWidgets('signs the reader out when the session is dead', (
      tester,
    ) async {
      jar.pairs.add({'sid': 'abc'});
      await storage.account.saveSession(MediumSession(const {'sid': 'abc'}));
      await storage.account.saveProfile(jane);
      await auth.init();

      expect(auth.isSignedIn, isTrue);

      _nextResult = null;

      await tester.pumpWidget(loginApp());
      late final bool refreshed;
      await pumpAction(
        tester,
        () async => refreshed = await auth.refreshProfile(),
      );

      expect(refreshed, isFalse);
      expect(
        auth.isSignedIn,
        isFalse,
        reason: 'a card that cannot refresh must not stay on Home',
      );
      expect(jar.removed, contains('sid'));
      expect(storage.account.profile, isNull);
    });
  });

  group('AuthService concurrency', () {
    test('a second sign-in is ignored while one is running', () async {
      jar.pairs.add({'sid': 'abc'});
      auth.isBusy.value = true;

      await auth.signIn();

      expect(
        auth.user.value,
        isNull,
        reason: 'the busy guard must stop a second attempt stacking up',
      );
    });
  });
}

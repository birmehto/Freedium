import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/storage/account_store.dart';
import 'package:freedium/core/storage/key_value_store.dart';
import 'package:freedium/features/account/models/medium_profile.dart';
import 'package:freedium/features/account/models/medium_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MemoryKeyValueStore kv;
  late AccountStore store;

  const profile = MediumProfile(
    handle: 'janedoe',
    name: 'Jane Doe',
    followerCount: 1200,
  );

  setUp(() {
    kv = MemoryKeyValueStore();
    store = AccountStore(kv);
  });

  group('MediumSession', () {
    test('is authenticated by any known session cookie', () {
      expect(MediumSession(const {'sid': 'abc'}).isAuthenticated, isTrue);
      expect(MediumSession(const {'uid': '1'}).isAuthenticated, isTrue);
      expect(MediumSession(const {'token': 'x'}).isAuthenticated, isTrue);
    });

    test('is not authenticated by analytics cookies alone', () {
      final session = MediumSession.fromCookiePairs([
        {'_ga': 'GA1.2'},
        {'amplitude': 'xyz'},
      ]);

      expect(session.isAuthenticated, isFalse);
    });

    test('drops analytics cookies and blanks', () {
      final session = MediumSession.fromCookiePairs([
        {'sid': 'abc'},
        {'_ga': 'GA1.2'},
        {'__s': 'tracker'},
        {'token': ''},
        {'uid': '7'},
      ]);

      expect(session.cookies, {'sid': 'abc', 'uid': '7'});
    });

    test('ignores entries that are not a single cookie', () {
      final session = MediumSession.fromCookiePairs([
        {'sid': 'abc', 'uid': '7'},
        {'token': 'x'},
      ]);

      expect(session.cookies, {'token': 'x'});
    });

    test('exposes cookies in cookie-jar shape', () {
      final session = MediumSession(const {'sid': 'abc', 'uid': '7'});

      expect(session.cookiePairs, [
        {'sid': 'abc'},
        {'uid': '7'},
      ]);
    });

    test('round-trips through JSON', () {
      final session = MediumSession(const {'sid': 'abc'});

      final restored = MediumSession.fromJson(session.toJson());

      expect(restored.isAuthenticated, isTrue);
      expect(restored.cookies, {'sid': 'abc'});
    });
  });

  group('AccountStore', () {
    test('starts empty', () {
      expect(store.session, isNull);
      expect(store.profile, isNull);
    });

    test('saves and reads a session and a profile', () async {
      await store.saveSession(MediumSession(const {'sid': 'abc'}));
      await store.saveProfile(profile);

      expect(store.session?.cookies, {'sid': 'abc'});
      expect(store.profile, profile);
    });

    test('ignores a session without an authenticating cookie', () async {
      await store.saveSession(MediumSession(const {'_ga': 'GA1.2'}));

      expect(
        store.session,
        isNull,
        reason: 'analytics cookies must not be mistaken for a session',
      );
    });

    test('ignores a profile without a handle', () async {
      await store.saveProfile(const MediumProfile(handle: '', name: 'Nobody'));

      expect(store.profile, isNull);
    });

    test('clear removes both keys', () async {
      await store.saveSession(MediumSession(const {'sid': 'abc'}));
      await store.saveProfile(profile);

      await store.clear();

      expect(store.session, isNull);
      expect(store.profile, isNull);
    });

    test('a cleared account cannot be resurrected by stale data', () async {
      await store.saveSession(MediumSession(const {'sid': 'abc'}));
      await store.saveProfile(profile);
      await store.clear();

      // Signing in again after a sign-out must not surface the old snapshot.
      final reread = AccountStore(kv);

      expect(reread.session, isNull);
      expect(reread.profile, isNull);
    });
  });
}

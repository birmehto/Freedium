import '../../features/account/models/medium_profile.dart';
import '../../features/account/models/medium_session.dart';
import 'key_value_store.dart';

/// The optional Medium account: the saved session and the cached profile.
///
/// Reading data and device settings each have their own store, and this is the
/// third: identity is neither, and keeping it separate means signing out is a
/// single [clear] that cannot take the library or the theme with it.
class AccountStore {
  AccountStore(this._store);

  /// Keys are kept stable so an existing account survives a refactor.
  static const String sessionKey = 'medium_session';
  static const String profileKey = 'medium_profile';

  final KeyValueStore _store;

  /// The saved session, or `null` when the reader never signed in.
  MediumSession? get session {
    final raw = _store.read(sessionKey);
    if (raw is! Map) return null;

    final session = MediumSession.fromJson(Map<String, dynamic>.from(raw));
    return session.isAuthenticated ? session : null;
  }

  /// The cached profile, or `null` when nothing is cached.
  MediumProfile? get profile {
    final raw = _store.read(profileKey);
    if (raw is! Map) return null;

    final profile = MediumProfile.fromJson(Map<String, dynamic>.from(raw));
    return profile.handle.isEmpty ? null : profile;
  }

  Future<void> saveSession(MediumSession session) {
    return _store.write(sessionKey, session.toJson());
  }

  Future<void> saveProfile(MediumProfile profile) {
    return _store.write(profileKey, profile.toJson());
  }

  /// Forgets the account entirely.
  ///
  /// Both keys are removed even when only one is present, so a half-written
  /// account can never be resurrected by a later launch.
  Future<void> clear() async {
    await _store.remove(sessionKey);
    await _store.remove(profileKey);
  }
}

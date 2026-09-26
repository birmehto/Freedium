import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../features/account/models/login_purpose.dart';
import '../../features/account/models/medium_profile.dart';
import '../../features/account/models/medium_session.dart';
import '../errors/app_exception.dart';
import '../routes/app_routes.dart';
import '../utils/app_log.dart';
import 'cookie_store.dart';
import 'storage_service.dart';

/// Owns the optional Medium account: who is signed in, the cached profile, and
/// the cookies that keep the session alive between launches.
///
/// Registered as a permanent service at startup so Home, the sign-in screen and
/// Settings all observe the same [user] and there is exactly one place that
/// touches credentials.
///
/// The account is optional by design. Nothing else in the app depends on it,
/// and signing out leaves the library, the theme and the mirrors untouched.
class AuthService extends GetxService {
  AuthService(this._storage, this._cookies);

  final StorageService _storage;
  final CookieStore _cookies;

  /// The signed-in author's profile, or `null` when signed out.
  final Rxn<MediumProfile> user = Rxn<MediumProfile>();

  /// True while a sign-in or profile refresh is in flight, so the Home button
  /// cannot start a second one on top of the first.
  final RxBool isBusy = false.obs;

  /// Whether a reader is currently signed in.
  bool get isSignedIn => user.value != null;

  /// The signed-in handle, or an empty string.
  String get handle => user.value?.handle ?? '';

  /// Restores a saved session and re-seeds the WebView cookie jar.
  ///
  /// The cached profile is published immediately so a returning reader does not
  /// wait on the network, and the session is only treated as restored if its
  /// cookies say so — a leftover profile on its own is not a session.
  ///
  /// A saved session that Medium has since invalidated stays valid locally
  /// until a refresh fails, which signs the reader out rather than leaving a
  /// card on Home that cannot do anything.
  Future<AuthService> init() async {
    final session = _storage.account.session;
    if (session == null) return this;

    await _cookies.write(
      MediumSession.origin,
      session.cookiePairs,
      domain: MediumSession.domain,
    );

    final cached = _storage.account.profile;
    if (cached != null) user.value = cached;

    return this;
  }

  /// Opens the sign-in screen and, on success, saves the session and profile.
  Future<void> signIn() async {
    if (isBusy.value) return;

    isBusy.value = true;
    try {
      final profile = await _openLogin(LoginPurpose.signIn);
      if (profile != null) await _acceptProfile(profile);
    } catch (error) {
      _report(error, 'signIn');
    } finally {
      isBusy.value = false;
    }
  }

  /// Re-reads the profile of an already signed-in reader.
  ///
  /// Returns `false` when the session turned out to be dead, in which case the
  /// account has been cleared so Home does not keep showing a card that cannot
  /// refresh.
  Future<bool> refreshProfile() async {
    if (isBusy.value) return false;

    isBusy.value = true;
    try {
      final profile = await _openLogin(LoginPurpose.refresh);
      if (profile == null) {
        // The cookie jar claimed a session but Medium no longer accepts it.
        await signOut();
        return false;
      }

      await _acceptProfile(profile);
      return true;
    } catch (error) {
      _report(error, 'refreshProfile');
      return false;
    } finally {
      isBusy.value = false;
    }
  }

  /// Forgets the account: cookies on the device, the saved session and the
  /// cached profile.
  Future<void> signOut() async {
    final session = _storage.account.session;
    if (session != null) {
      await _cookies.remove(
        MediumSession.origin,
        session.cookies.keys,
        domain: MediumSession.domain,
      );
    }

    await _storage.account.clear();
    user.value = null;
  }

  /// Reads the live cookie jar and keeps it as a session.
  Future<MediumSession?> captureSession() async {
    final pairs = await _cookies.read(MediumSession.origin);
    if (pairs.isEmpty) return null;

    return MediumSession.fromCookiePairs(pairs);
  }

  /// Opens the sign-in screen and returns the profile it read, if any.
  Future<MediumProfile?> _openLogin(LoginPurpose purpose) async {
    // Deliberately untyped: GetX builds a `GetPageRoute<dynamic>`, which is not
    // a `Route<MediumProfile>`, so a type argument here makes Flutter's
    // `pushNamed` throw a TypeError the moment the route is pushed. The result
    // is checked below instead of being cast.
    //
    // `toNamed` also hands back a nullable Future and quietly returns null when
    // it cannot push — including via its duplicate-route guard, which is on by
    // default. Opting out keeps a second tap from looking like a silent
    // refusal, and the null check keeps "never opened" from being read as "the
    // reader backed out".
    final navigation = Get.toNamed(
      AppRoutes.login,
      arguments: purpose,
      preventDuplicates: false,
    );

    if (navigation == null) {
      appLog(
        'Could not open ${AppRoutes.login}',
        name: 'Account',
        level: LogLevel.warning,
      );
      return null;
    }

    final result = await navigation;
    return result is MediumProfile ? result : null;
  }

  /// Persists a freshly read profile together with the cookies that produced
  /// it.
  Future<void> _acceptProfile(MediumProfile profile) async {
    final session = await captureSession();

    if (session == null || !session.isAuthenticated) {
      // A profile without a session cookie cannot be restored next launch, so
      // it is shown but never saved as one.
      user.value = profile;
      _showMessage(
        'Signed in for this session only. Medium cookies could not be saved.',
      );
      return;
    }

    await _storage.account.saveSession(session);
    await _storage.account.saveProfile(profile);
    user.value = profile;
  }

  void _report(Object error, String context) {
    final exception = AppException.from(error, context: context);

    appLog('$exception', name: 'Account', level: LogLevel.error);

    _showMessage(exception.userMessage);
  }

  /// Shows a transient message, if a context is available at that moment.
  ///
  /// Never throws: by the time a result is handled the screen that produced it
  /// may already be gone, and a message that cannot be shown must not abort the
  /// sign-in it was reporting on.
  void _showMessage(String message) {
    final context = Get.context;
    if (context == null || !context.mounted) return;

    try {
      M3ESnackbar.show(context, message: message);
    } catch (error) {
      appLog(
        'Could not show message: $error',
        name: 'Account',
        level: LogLevel.warning,
      );
    }
  }
}

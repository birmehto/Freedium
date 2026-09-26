import 'dart:async';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

import '../../../core/services/cookie_store.dart';
import '../../../core/utils/app_log.dart';
import '../models/login_purpose.dart';
import '../models/medium_profile.dart';
import '../models/medium_profile_parser.dart';
import '../models/medium_session.dart';

/// Drives the Medium sign-in screen and hands the profile it read back to
/// whoever opened it.
///
/// Medium offers no sign-in API, so the reader authenticates on Medium's own
/// page in a WebView and the profile is read from that same session. Nothing
/// typed into the form is ever seen here: this only ever sees the resulting
/// cookies and a public profile page.
///
/// The screen is deliberately independent of [AuthService] — it returns a
/// profile rather than saving one, so persisting the session stays the
/// service's single responsibility.
class LoginController extends GetxController {
  LoginController(this._cookies);

  /// Used to notice that Medium has just issued a session, so the flow can ask
  /// for the profile page explicitly instead of hoping the reader happens to
  /// land on one.
  final CookieStore _cookies;

  /// Where the reader signs in.
  ///
  /// This is Medium's own mobile sign-in route, not `/login`, which now only
  /// redirects to it. It is asked to send the reader to their own profile
  /// afterwards, so a completed sign-in lands on the page that describes the
  /// reader rather than on the feed, which carries no handle to read.
  static const String signInUrl =
      '${MediumSession.origin}/m/signin'
      '?redirect=https%3A%2F%2Fmedium.com%2Fme'
      '&loginType=default';

  /// Medium's own-profile route, which redirects to the sign-in page when the
  /// session is not actually valid.
  static const String profileUrl = '${MediumSession.origin}/me';

  /// How many times one page is re-read before it is treated as not-a-profile.
  ///
  /// Medium renders its profile header after hydration, so a page that loaded
  /// without a handle is usually just early rather than signed out.
  static const int maxProfileAttempts = 8;

  /// Gap between re-reads of the same page.
  static const Duration profileRetryDelay = Duration(milliseconds: 600);

  /// Hosts the sign-in flow may navigate to: Medium itself plus the identity
  /// providers it offers.
  ///
  /// An entry allows that host and its subdomains, so the narrowest entry that
  /// works is the best one. `accounts.youtube.com` looks like scope creep but is
  /// not: signing in with Google on Medium detours through it to move the
  /// session between Google's domains, and blocking it deadlocks the flow with
  /// no visible error.
  static const List<String> allowedAuthHosts = [
    'medium.com',
    'google.com',
    'accounts.youtube.com',
    'apple.com',
    'github.com',
    'twitter.com',
    'facebook.com',
  ];

  final RxDouble progress = 0.0.obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  late LoginPurpose purpose;

  InAppWebViewController? webViewController;

  bool _finishing = false;
  int _attempts = 0;

  /// Set once the flow has asked Medium for `/me`, so later page loads keep
  /// looking for a profile rather than re-requesting it forever.
  bool _requestedProfilePage = false;

  /// The main-frame URL currently displayed, used to tell whether the profile
  /// page is already what is on screen.
  String _currentUrl = '';

  /// Bumped on every main-frame navigation so a retry chain belonging to a page
  /// that has already been replaced stops instead of reading the new document.
  int _generation = 0;

  /// The first URL to load, which depends on why the screen was opened.
  String get initialUrl =>
      purpose == LoginPurpose.refresh ? profileUrl : signInUrl;

  @override
  void onInit() {
    super.onInit();
    purpose = loginPurposeFrom(Get.arguments);
    _currentUrl = initialUrl;
  }

  // ────────────────────────────── WebView ────────────────────────────────

  void setWebViewController(InAppWebViewController controller) {
    webViewController = controller;
  }

  void onPageStart(String? url) {
    _generation++;
    _attempts = 0;

    if (url != null) _currentUrl = url;

    errorMessage.value = '';
    isLoading.value = true;
    progress.value = 0;

    appLog('Login.onPageStart: url=$url', name: 'Account');
  }

  void updateProgress(double progress) {
    this.progress.value = (progress / 100).clamp(0.0, 1.0).toDouble();
  }

  void onPageLoaded() {
    isLoading.value = false;
    unawaited(_readProfile());
  }

  void onPageError(String message) {
    isLoading.value = false;

    // A refresh with no profile to show has nothing to fall back to, so the
    // failure is surfaced. While signing in, a failed page load is usually just
    // a hiccup on the way to the profile and the reader can simply retry.
    if (purpose == LoginPurpose.refresh) {
      errorMessage.value = message;
    }
  }

  void onConsoleMessage(ConsoleMessage message) {
    if (message.messageLevel != ConsoleMessageLevel.ERROR) return;
    appLog('Login console: ${message.message}', name: 'Account');
  }

  /// Decides what a navigation is allowed to do.
  ///
  /// A refused navigation is invisible on screen — the page simply stops
  /// responding — so every refusal is logged. That is what turns "sign-in is
  /// stuck" into an answer.
  NavigationActionPolicy resolveNavigation(
    WebUri? url, {
    bool isMainFrame = true,
  }) {
    if (url == null) return NavigationActionPolicy.CANCEL;

    final scheme = url.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      _refuse(url, isMainFrame: isMainFrame, reason: 'scheme $scheme');
      return NavigationActionPolicy.CANCEL;
    }

    // Sub-frames belong to the sign-in flow's own widgets, such as an embedded
    // captcha or an OAuth card, and are never a navigation away from it.
    if (!isMainFrame) return NavigationActionPolicy.ALLOW;

    if (isAllowedAuthHost(url.host)) return NavigationActionPolicy.ALLOW;

    _refuse(url, isMainFrame: isMainFrame, reason: 'host not in the flow');
    return NavigationActionPolicy.CANCEL;
  }

  void _refuse(
    WebUri url, {
    required bool isMainFrame,
    required String reason,
  }) {
    appLog(
      'Login refused a ${isMainFrame ? 'navigation' : 'subframe'} to $url ($reason)',
      name: 'Account',
      level: LogLevel.warning,
    );
  }

  /// Whether [host] is part of the sign-in flow, matching subdomains so
  /// `accounts.google.com` is allowed without opening the door to `google.com`.
  static bool isAllowedAuthHost(String host) {
    final normalized = host.trim().toLowerCase();

    return allowedAuthHosts.any(
      (allowed) => normalized == allowed || normalized.endsWith('.$allowed'),
    );
  }

  // ─────────────────────────────── actions ──────────────────────────────

  /// Reloads the sign-in page after a failure.
  Future<void> retry() async {
    errorMessage.value = '';
    isLoading.value = true;
    progress.value = 0;

    await webViewController?.loadUrl(
      urlRequest: URLRequest(url: WebUri(initialUrl)),
    );
  }

  // ─────────────────────────────── profile ───────────────────────────────

  /// Reads the reader's profile off the loaded page, retrying while the document
  /// is still rendering and finishing the screen the moment a profile appears.
  Future<void> _readProfile() async {
    final controller = webViewController;
    if (_finishing || isClosed || controller == null) return;

    if (_attempts >= maxProfileAttempts) {
      if (purpose == LoginPurpose.refresh) _finish(null);
      return;
    }

    final generation = _generation;
    _attempts++;

    final profile = await _extractProfile(controller);
    if (_finishing || isClosed) return;

    if (profile != null) {
      _finish(profile);
      return;
    }

    // The page moved on while this read was in flight, so the new document gets
    // its own attempt budget instead of racing this one.
    if (generation != _generation) return;

    // Medium sends a freshly authenticated reader to a page that has no handle
    // in it at all, so waiting for one to appear on its own would never end. As
    // soon as a session exists, the profile page is requested explicitly.
    if (await _openProfilePageIfSignedIn(controller, generation)) return;

    unawaited(Future<void>.delayed(profileRetryDelay, _readProfile));
  }

  /// Navigates to `/me` when Medium has issued a session but the visible page is
  /// not the profile page. Returns true when a navigation was started.
  Future<bool> _openProfilePageIfSignedIn(
    InAppWebViewController controller,
    int generation,
  ) async {
    if (_requestedProfilePage) return false;
    if (isProfilePage(_currentUrl)) return false;

    if (!await _hasSession()) return false;
    if (_finishing || isClosed || generation != _generation) return false;

    _requestedProfilePage = true;
    appLog('Login: session found, loading $profileUrl', name: 'Account');

    await controller.loadUrl(urlRequest: URLRequest(url: WebUri(profileUrl)));

    return true;
  }

  /// Whether a URL is already Medium's own-profile page, ignoring the query
  /// string and trailing slash that Medium's redirects add.
  ///
  /// Public so the routing decision can be unit tested without a WebView. Without
  /// it, a sign-in that lands on `/me` would ask for `/me` again.
  static bool isProfilePage(String url) {
    if (url.isEmpty) return false;

    final path = Uri.tryParse(url)?.path ?? url;
    final trimmed = path.endsWith('/')
        ? path.substring(0, path.length - 1)
        : path;

    return trimmed == '/me';
  }

  /// Whether the cookie jar now holds a session Medium would honour.
  Future<bool> _hasSession() async {
    try {
      final session = MediumSession.fromCookiePairs(
        await _cookies.read(MediumSession.origin),
      );
      return session.isAuthenticated;
    } catch (error) {
      appLog(
        'Could not read the session cookie jar: $error',
        name: 'Account',
        level: LogLevel.warning,
      );
      return false;
    }
  }

  Future<MediumProfile?> _extractProfile(
    InAppWebViewController controller,
  ) async {
    try {
      final raw = await controller.evaluateJavascript(
        source: MediumProfileParser.extractScript,
      );

      return MediumProfileParser.fromJsonString(raw as String?);
    } catch (error) {
      appLog(
        'Could not read Medium profile: $error',
        name: 'Account',
        level: LogLevel.warning,
      );
      return null;
    }
  }

  void _finish(MediumProfile? profile) {
    if (_finishing) return;
    _finishing = true;

    // Untyped on purpose: the caller checks what it gets back, and a typed
    // route result is not something GetX can honour here.
    Get.back<MediumProfile>(result: profile);
  }
}

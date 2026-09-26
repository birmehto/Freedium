/// What the sign-in screen is being opened for.
///
/// The screen is the same either way — a WebView on Medium that reads the
/// reader's own profile once a session exists — but the two purposes need
/// different behaviour when no profile ever appears.
enum LoginPurpose {
  /// A reader without a session is expected to create one. The screen stays
  /// open while they do, because a failed attempt is not an error.
  signIn,

  /// A session is already restored, so the profile is read from the first page
  /// that yields one. Running out of attempts is a failure, not a prompt.
  refresh,
}

/// Reads the purpose a sign-in screen was opened for, defaulting to
/// [LoginPurpose.signIn] when the arguments are missing or unexpected.
LoginPurpose loginPurposeFrom(Object? arguments) {
  return arguments is LoginPurpose ? arguments : LoginPurpose.signIn;
}

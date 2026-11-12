/// Why a Drive step failed. One type per cause; the caller maps each to what
/// the user sees and logs it (the domain never logs).
sealed class DriveException implements Exception {
  const DriveException();
}

/// The SSO or the workplace URL is not configured, or is not allowed in this
/// build (cleartext in release).
final class DriveNotConfigured extends DriveException {
  const DriveNotConfigured();
}

/// The user closed the browser or denied the sign-in. Silent for the user.
final class DriveSignInCancelled extends DriveException {
  const DriveSignInCancelled();
}

/// The account changed or the session owner was disposed during sign-in, so
/// the result is dropped. Silent for the user.
final class DriveSessionSuperseded extends DriveException {
  const DriveSessionSuperseded();
}

/// The sign-in ran and failed; [reason] says where.
final class DriveSignInFailed extends DriveException {
  const DriveSignInFailed(this.reason);

  final DriveSignInFailure reason;
}

/// The SSO gave no workplace for this user, or the template did not resolve to
/// a URL.
final class DriveWorkplaceUnknown extends DriveException {
  const DriveWorkplaceUnknown();
}

/// Drive refused the id token, again after a new sign-in.
final class DriveExchangeRejected extends DriveException {
  const DriveExchangeRejected();
}

/// The user's Drive has no Chat app, so it trades no token for this app
/// (`400 chat is not installed`). Only an administrator can install it.
final class DriveChatAppMissing extends DriveException {
  const DriveChatAppMissing();
}

/// Drive could not create the picker intent (network, server, bad answer).
final class DriveIntentFailed extends DriveException {
  const DriveIntentFailed();
}

/// A Drive or SSO request was refused because the server is rate limiting it.
final class DriveRateLimited extends DriveException {
  const DriveRateLimited();
}

/// A Drive or SSO request did not finish before its network timeout.
final class DriveTimedOut extends DriveException {
  const DriveTimedOut();
}

/// A Drive or SSO request could not establish a network connection.
final class DriveOffline extends DriveException {
  const DriveOffline();
}

enum DriveSignInFailure {
  discovery,
  browser,
  callbackError,
  stateMismatch,
  missingCode,
  tokenEndpoint,
  invalidIdToken,

  /// The SSO signed in someone other than the Matrix account that asked.
  otherAccount,
}

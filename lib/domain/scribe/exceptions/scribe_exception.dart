/// Why a Scribe request failed, for the causes only the Scribe has. One type
/// per cause; the caller maps each to what the user sees and logs it (the
/// domain never logs). The Scribe signs in and trades its token like Drive, so
/// sign-in, token and network failures stay `DriveException`s.
sealed class ScribeException implements Exception {
  const ScribeException();
}

/// The room does not offer the Scribe; nothing was sent.
final class ScribeNotOffered extends ScribeException {
  const ScribeNotOffered();
}

/// The draft is blank; nothing was sent.
final class ScribeEmptyDraft extends ScribeException {
  const ScribeEmptyDraft();
}

/// The workplace could not rewrite the draft (server error, empty or
/// unreadable answer).
final class ScribeRewriteFailed extends ScribeException {
  const ScribeRewriteFailed();
}

/// The active account has no such room.
final class ScribeRoomNotFound extends ScribeException {
  const ScribeRoomNotFound();
}

/// The homeserver did not save the room's Scribe switch.
final class ScribeSwitchFailed extends ScribeException {
  const ScribeSwitchFailed();
}

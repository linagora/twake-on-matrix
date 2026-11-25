sealed class ScribeException implements Exception {
  const ScribeException();
}

final class ScribeNotOffered extends ScribeException {
  const ScribeNotOffered();
}

final class ScribeEmptyDraft extends ScribeException {
  const ScribeEmptyDraft();
}

final class ScribeRewriteFailed extends ScribeException {
  const ScribeRewriteFailed();
}

final class ScribeRoomNotFound extends ScribeException {
  const ScribeRoomNotFound();
}

final class ScribeSwitchFailed extends ScribeException {
  const ScribeSwitchFailed();
}

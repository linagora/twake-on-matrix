sealed class ProfileException implements Exception {
  const ProfileException(this.cause);

  final Object cause;
}

final class FetchOwnProfileException extends ProfileException {
  const FetchOwnProfileException(super.cause);
}

final class FetchAccountProfilesException extends ProfileException {
  const FetchAccountProfilesException(super.cause);
}

final class SaveOwnProfileException extends ProfileException {
  const SaveOwnProfileException(super.cause);
}

final class RemoveOwnAvatarException extends ProfileException {
  const RemoveOwnAvatarException(super.cause);
}

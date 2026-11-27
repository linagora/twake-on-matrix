sealed class UserInfoException implements Exception {
  const UserInfoException(this.cause);

  final Object cause;
}

class GetUserInfoVisibilityException extends UserInfoException {
  const GetUserInfoVisibilityException(super.cause);
}

class UpdateUserInfoVisibilityException extends UserInfoException {
  const UpdateUserInfoVisibilityException(super.cause);
}

class GetUserInfoException extends UserInfoException {
  const GetUserInfoException(super.cause);
}

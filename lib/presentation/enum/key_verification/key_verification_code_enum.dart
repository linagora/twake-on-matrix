enum KeyVerificationCodeEnum {
  user;

  String get code => switch (this) {
    KeyVerificationCodeEnum.user => 'm.user',
  };
}

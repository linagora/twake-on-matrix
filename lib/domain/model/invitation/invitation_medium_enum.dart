enum InvitationMediumEnum {
  email,
  phone;

  String get value {
    switch (this) {
      case InvitationMediumEnum.email:
        return 'email';
      case InvitationMediumEnum.phone:
        return 'phone';
    }
  }
}

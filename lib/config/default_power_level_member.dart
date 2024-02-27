enum DefaultPowerLevelMember {
  user,
  moderator,
  admin;

  int get powerLevel {
    switch (this) {
      case DefaultPowerLevelMember.user:
        return 0;
      case DefaultPowerLevelMember.moderator:
        return 50;
      case DefaultPowerLevelMember.admin:
        return 100;
      default:
        return 0;
    }
  }
}

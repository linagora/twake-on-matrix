enum DefaultPowerLevelMember {
  user,
  moderator,
  admin,
  owner;

  int get powerLevel {
    switch (this) {
      case DefaultPowerLevelMember.user:
        return 0;
      case DefaultPowerLevelMember.moderator:
        return 50;
      case DefaultPowerLevelMember.admin:
        return 80;
      case DefaultPowerLevelMember.owner:
        return 100;
      default:
        return 0;
    }
  }

  String get displayName {
    switch (this) {
      case DefaultPowerLevelMember.user:
        return 'User';
      case DefaultPowerLevelMember.moderator:
        return 'Moderator';
      case DefaultPowerLevelMember.admin:
        return 'Admin';
      case DefaultPowerLevelMember.owner:
        return 'Owner';
      default:
        return '';
    }
  }
}

import 'package:fluffychat/config/default_permission_level_member.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

enum DefaultPowerLevelMember {
  guest,
  member,
  moderator,
  admin,
  owner,
  none;

  static List<int> powerLevelAvailable() => [
    DefaultPowerLevelMember.guest.powerLevel,
    DefaultPowerLevelMember.member.powerLevel,
    DefaultPowerLevelMember.moderator.powerLevel,
    DefaultPowerLevelMember.admin.powerLevel,
    DefaultPowerLevelMember.owner.powerLevel,
  ];

  static DefaultPowerLevelMember getDefaultPowerLevelByUsersDefault({
    required int usersDefault,
  }) {
    int result = powerLevelAvailable().first;

    for (final int level in powerLevelAvailable()) {
      if (usersDefault >= level) {
        result = level;
      } else {
        break;
      }
    }

    return DefaultPowerLevelMember.values.firstWhere(
      (element) => element.powerLevel == result,
      orElse: () => DefaultPowerLevelMember.none,
    );
  }

  int get powerLevel {
    switch (this) {
      case DefaultPowerLevelMember.guest:
        return 0;
      case DefaultPowerLevelMember.member:
        return 10;
      case DefaultPowerLevelMember.moderator:
        return 50;
      case DefaultPowerLevelMember.admin:
        return 80;
      case DefaultPowerLevelMember.owner:
        return 90;
      case DefaultPowerLevelMember.none:
        return 100;
    }
  }

  String displayName(
    BuildContext context, {
    List<DefaultPowerLevelMember> hidden = const [],
  }) {
    if (hidden.contains(this)) return '';
    switch (this) {
      case DefaultPowerLevelMember.member:
        return L10n.of(context)!.member;
      case DefaultPowerLevelMember.moderator:
        return L10n.of(context)!.moderator;
      case DefaultPowerLevelMember.admin:
        return L10n.of(context)!.admin;
      case DefaultPowerLevelMember.owner:
        return L10n.of(context)!.owner;
      case DefaultPowerLevelMember.guest:
        return L10n.of(context)!.readOnly;
      case DefaultPowerLevelMember.none:
        return '';
    }
  }

  List<DefaultPermissionLevelMember> permissionForGuest(BuildContext context) {
    return [DefaultPermissionLevelMember.invitePeopleToTheRoom];
  }

  List<DefaultPermissionLevelMember> permissionForMember(BuildContext context) {
    return [
      DefaultPermissionLevelMember.sendMessages,
      DefaultPermissionLevelMember.sendReactions,
      DefaultPermissionLevelMember.deleteMessagesSentByMe,
      DefaultPermissionLevelMember.notifyEveryoneUsingRoom,
      DefaultPermissionLevelMember.joinCall,
    ];
  }

  List<DefaultPermissionLevelMember> permissionForModerator(
    BuildContext context,
  ) {
    return [
      DefaultPermissionLevelMember.removeMembers,
      DefaultPermissionLevelMember.deleteMessagesSentByOthers,
      DefaultPermissionLevelMember.pinMessageForEveryone,
      DefaultPermissionLevelMember.startCall,
    ];
  }

  List<DefaultPermissionLevelMember> permissionForAdmin(BuildContext context) {
    return [
      DefaultPermissionLevelMember.changeGroupName,
      DefaultPermissionLevelMember.changeGroupDescription,
      DefaultPermissionLevelMember.changeGroupAvatar,
      DefaultPermissionLevelMember.changeGroupHistoryVisibility,
      DefaultPermissionLevelMember.assignRoles,
    ];
  }
}

import 'package:fluffychat/config/default_permission_level_member.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

enum DefaultPowerLevelMember {
  guest,
  member,
  moderator,
  admin,
  owner,
  none;

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
      default:
        return 0;
    }
  }

  String displayName(BuildContext context) {
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
      default:
        return '';
    }
  }

  List<DefaultPermissionLevelMember> permissionForGuest(BuildContext context) {
    return [
      DefaultPermissionLevelMember.invitePeopleToTheRoom,
    ];
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

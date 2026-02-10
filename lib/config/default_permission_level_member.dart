import 'package:fluffychat/resource/image_paths.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

enum DefaultPermissionLevelMember {
  sendMessages,
  invitePeopleToTheRoom,
  sendReactions,
  deleteMessagesSentByMe,
  notifyEveryoneUsingRoom,
  joinCall,
  removeMembers,
  deleteMessagesSentByOthers,
  pinMessageForEveryone,
  startCall,
  changeGroupName,
  changeGroupDescription,
  changeGroupAvatar,
  changeGroupHistoryVisibility,
  assignRoles;

  String title(BuildContext context) {
    switch (this) {
      case DefaultPermissionLevelMember.sendMessages:
        return L10n.of(context)!.sendMessages;
      case DefaultPermissionLevelMember.invitePeopleToTheRoom:
        return L10n.of(context)!.invitePeopleToTheRoom;
      case DefaultPermissionLevelMember.sendReactions:
        return L10n.of(context)!.sendReactions;
      case DefaultPermissionLevelMember.deleteMessagesSentByMe:
        return L10n.of(context)!.deleteMessagesSentByMe;
      case DefaultPermissionLevelMember.notifyEveryoneUsingRoom:
        return L10n.of(context)!.notifyEveryoneUsingRoom;
      case DefaultPermissionLevelMember.joinCall:
        return L10n.of(context)!.joinCall;
      case DefaultPermissionLevelMember.removeMembers:
        return L10n.of(context)!.removeMembers;
      case DefaultPermissionLevelMember.deleteMessagesSentByOthers:
        return L10n.of(context)!.deleteMessagesSentByOthers;
      case DefaultPermissionLevelMember.pinMessageForEveryone:
        return L10n.of(context)!.pinMessageForEveryone;
      case DefaultPermissionLevelMember.startCall:
        return L10n.of(context)!.startCall;
      case DefaultPermissionLevelMember.changeGroupName:
        return L10n.of(context)!.changeGroupName;
      case DefaultPermissionLevelMember.changeGroupDescription:
        return L10n.of(context)!.changeGroupDescription;
      case DefaultPermissionLevelMember.changeGroupAvatar:
        return L10n.of(context)!.changeGroupAvatar;
      case DefaultPermissionLevelMember.changeGroupHistoryVisibility:
        return L10n.of(context)!.changeGroupHistoryVisibility;
      case DefaultPermissionLevelMember.assignRoles:
        return L10n.of(context)!.assignRoles;
    }
  }

  String? imagePath() {
    switch (this) {
      case DefaultPermissionLevelMember.deleteMessagesSentByMe:
      case DefaultPermissionLevelMember.deleteMessagesSentByOthers:
        return ImagePaths.icChatError;
      case DefaultPermissionLevelMember.assignRoles:
        return ImagePaths.icShieldLockFill;
      case DefaultPermissionLevelMember.sendMessages:
      case DefaultPermissionLevelMember.invitePeopleToTheRoom:
      case DefaultPermissionLevelMember.sendReactions:
      case DefaultPermissionLevelMember.notifyEveryoneUsingRoom:
      case DefaultPermissionLevelMember.joinCall:
      case DefaultPermissionLevelMember.removeMembers:
      case DefaultPermissionLevelMember.pinMessageForEveryone:
      case DefaultPermissionLevelMember.startCall:
      case DefaultPermissionLevelMember.changeGroupName:
      case DefaultPermissionLevelMember.changeGroupDescription:
      case DefaultPermissionLevelMember.changeGroupAvatar:
      case DefaultPermissionLevelMember.changeGroupHistoryVisibility:
        return null;
    }
  }

  IconData? icon() {
    switch (this) {
      case DefaultPermissionLevelMember.sendMessages:
        return Icons.chat_outlined;
      case DefaultPermissionLevelMember.invitePeopleToTheRoom:
        return Icons.person_add_outlined;
      case DefaultPermissionLevelMember.sendReactions:
        return Icons.add_reaction_outlined;
      case DefaultPermissionLevelMember.deleteMessagesSentByMe:
        return null;
      case DefaultPermissionLevelMember.notifyEveryoneUsingRoom:
        return Icons.notifications_outlined;
      case DefaultPermissionLevelMember.joinCall:
        return Icons.phone_outlined;
      case DefaultPermissionLevelMember.removeMembers:
        return Icons.person_remove_outlined;
      case DefaultPermissionLevelMember.deleteMessagesSentByOthers:
        return null;
      case DefaultPermissionLevelMember.pinMessageForEveryone:
        return Icons.push_pin_outlined;
      case DefaultPermissionLevelMember.startCall:
        return Icons.phone_outlined;
      case DefaultPermissionLevelMember.changeGroupName:
        return Icons.settings_outlined;
      case DefaultPermissionLevelMember.changeGroupDescription:
        return Icons.topic_outlined;
      case DefaultPermissionLevelMember.changeGroupAvatar:
        return Icons.image_outlined;
      case DefaultPermissionLevelMember.changeGroupHistoryVisibility:
        return Icons.history_outlined;
      case DefaultPermissionLevelMember.assignRoles:
        return null;
    }
  }

  Widget permissionViewWidget(BuildContext context) {
    switch (this) {
      case DefaultPermissionLevelMember.sendMessages:
      case DefaultPermissionLevelMember.invitePeopleToTheRoom:
      case DefaultPermissionLevelMember.sendReactions:
      case DefaultPermissionLevelMember.deleteMessagesSentByMe:
      case DefaultPermissionLevelMember.notifyEveryoneUsingRoom:
      case DefaultPermissionLevelMember.joinCall:
      case DefaultPermissionLevelMember.removeMembers:
      case DefaultPermissionLevelMember.deleteMessagesSentByOthers:
      case DefaultPermissionLevelMember.pinMessageForEveryone:
      case DefaultPermissionLevelMember.startCall:
      case DefaultPermissionLevelMember.changeGroupName:
      case DefaultPermissionLevelMember.changeGroupDescription:
      case DefaultPermissionLevelMember.changeGroupAvatar:
      case DefaultPermissionLevelMember.changeGroupHistoryVisibility:
      case DefaultPermissionLevelMember.assignRoles:
        return _permissionItem(context, this);
    }
  }

  Widget _permissionItem(
    BuildContext context,
    DefaultPermissionLevelMember permission,
  ) {
    return Container(
      height: 48,
      padding: const EdgeInsets.only(left: 72, right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (permission.icon() != null)
            Icon(
              permission.icon(),
              size: 24,
              color: LinagoraSysColors.material().onSurface,
            ),
          if (permission.imagePath() != null)
            SvgPicture.asset(
              permission.imagePath()!,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                LinagoraSysColors.material().onSurface,
                BlendMode.srcIn,
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              permission.title(context),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: LinagoraSysColors.material().onSurface,
              ),
            ),
          ),
          Container(
            width: 38,
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: LinagoraStateLayer(
                LinagoraSysColors.material().onSurface,
              ).opacityLayer2,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: LinagoraSysColors.material().surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  size: 16,
                  color: LinagoraSysColors.material().onSurface.withOpacity(
                    0.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

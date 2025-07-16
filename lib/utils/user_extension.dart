import 'package:fluffychat/config/default_power_level_member.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_body.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

extension UserExtension on User {
  static const double fixedDialogWidth = 448;

  static const EdgeInsets closeButtonPadding = EdgeInsets.all(16);

  DefaultPowerLevelMember get getDefaultPowerLevelMember {
    switch (powerLevel) {
      case 0:
        return DefaultPowerLevelMember.guest;
      case 10:
        return DefaultPowerLevelMember.member;
      case 50:
        return DefaultPowerLevelMember.moderator;
      case 80:
        return DefaultPowerLevelMember.admin;
      case 100:
        return DefaultPowerLevelMember.owner;
      default:
        return DefaultPowerLevelMember.guest;
    }
  }

  bool get isOwnerRole {
    return getDefaultPowerLevelMember == DefaultPowerLevelMember.owner;
  }

  Future openProfileDialog({
    required BuildContext context,
    VoidCallback? onUpdatedMembers,
  }) =>
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          contentPadding: const EdgeInsets.all(0),
          backgroundColor: LinagoraRefColors.material().primary[100],
          surfaceTintColor: Colors.transparent,
          content: SizedBox(
            width: fixedDialogWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: closeButtonPadding,
                        child: IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ),
                    ),
                    ProfileInfoBody(
                      user: this,
                      onNewChatOpen: () {
                        Navigator.of(dialogContext).pop();
                      },
                      onUpdatedMembers: onUpdatedMembers,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

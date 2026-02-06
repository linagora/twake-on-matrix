import 'package:fluffychat/pages/chat_details/chat_details_group_actions_view.dart';
import 'package:fluffychat/pages/chat_details/chat_details_group_info_background_view.dart';
import 'package:fluffychat/pages/chat_details/chat_details_group_information_view.dart';
import 'package:fluffychat/pages/chat_details/chat_details_group_secondary_avatar.dart';
import 'package:fluffychat/pages/chat_details/chat_details_view_style.dart';
import 'package:fluffychat/presentation/extensions/room_summary_extension.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class ChatDetailsHeaderStack extends StatelessWidget {
  const ChatDetailsHeaderStack({
    super.key,
    required this.room,
    required this.animationController,
    required this.groupInfoHeight,
    required this.maxGroupInfoHeight,
    required this.onMessage,
    required this.onSearch,
    required this.onToggleNotification,
    required this.muteNotifier,
    required this.onGroupInfoTap,
  });

  final Room room;
  final AnimationController animationController;
  final double groupInfoHeight;
  final double maxGroupInfoHeight;
  final VoidCallback onMessage;
  final VoidCallback onSearch;
  final VoidCallback onToggleNotification;
  final ValueNotifier<PushRuleState> muteNotifier;
  final VoidCallback onGroupInfoTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ChatDetailsGroupSecondaryAvatar(
            animationController: animationController,
            mxContent: room.avatar,
            name: room.getLocalizedDisplayname(),
            fontSize: ChatDetailViewStyle.avatarFontSize,
          ),
        ),
        Positioned.fill(
          child: ChatDetailsGroupInfoBackgroundView(
            animationController: animationController,
          ),
        ),
        Column(
          children: [
            ChatDetailsGroupInformationView(
              height: groupInfoHeight,
              maxHeight: maxGroupInfoHeight,
              animationController: animationController,
              avatarUri: room.avatar,
              displayName: room.getLocalizedDisplayname(),
              membersCount: room.summary.actualMembersCount,
              onTap: onGroupInfoTap,
            ),
            ChatDetailsGroupActionsView(
              onMessage: onMessage,
              onSearch: onSearch,
              onToggleNotification: onToggleNotification,
              muteNotifier: muteNotifier,
              animationController: animationController,
            ),
          ],
        ),
      ],
    );
  }
}

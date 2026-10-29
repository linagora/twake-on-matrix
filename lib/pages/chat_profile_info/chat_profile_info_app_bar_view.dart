import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncValue, AsyncValueExtensions;
import 'package:twake_chat/domain/model/user_info/user_info.dart';
import 'package:twake_chat/pages/chat_details/chat_details_group_actions_view.dart';
import 'package:twake_chat/pages/chat_details/chat_details_group_info_background_view.dart';
import 'package:twake_chat/pages/chat_details/chat_details_group_information_view.dart';
import 'package:twake_chat/pages/chat_profile_info/chat_profile_info_details.dart';
import 'package:twake_chat/pages/chat_profile_info/chat_profile_info_style.dart';
import 'package:twake_chat/widgets/avatar/secondary_avatar.dart';
import 'package:flutter/cupertino.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart' hide Contact;

class ChatProfileInfoAppBarView extends StatelessWidget {
  const ChatProfileInfoAppBarView({
    super.key,
    this.avatarUri,
    this.displayName,
    this.matrixId,
    required this.userInfo,
    required this.isBlockedUserNotifier,
    this.onUnblockUser,
    this.onBlockUser,
    required this.blockUserLoadingNotifier,
    this.room,
    this.onLeaveChat,
    required this.groupInfoHeight,
    required this.maxGroupInfoHeight,
    required this.onChatInfoTap,
    required this.animationController,
    this.getLocalizedStatusMessage,
    required this.onMessage,
    required this.onSearch,
  });

  final Uri? avatarUri;
  final String? displayName;
  final String? matrixId;
  final AsyncValue<UserInfo> userInfo;
  final ValueNotifier<bool> isBlockedUserNotifier;
  final void Function()? onUnblockUser;
  final void Function()? onBlockUser;
  final ValueNotifier<bool?> blockUserLoadingNotifier;
  final Room? room;
  final void Function()? onLeaveChat;
  final double groupInfoHeight;
  final double maxGroupInfoHeight;
  final VoidCallback onChatInfoTap;
  final AnimationController animationController;
  final String? getLocalizedStatusMessage;
  final VoidCallback onMessage;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final userInfoModel = userInfo.value;
    return Column(
      children: [
        Stack(
          children: [
            Positioned.fill(
              child: _buildAvatarWidget(
                userInfoModel: userInfoModel,
                animationController: animationController,
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
                  displayName: userInfo.isLoading
                      ? null
                      : userInfoModel?.displayName ?? displayName ?? '',
                  subTitle: getLocalizedStatusMessage,
                  onTap: onChatInfoTap,
                ),
                ChatDetailsGroupActionsView(
                  onMessage: onMessage,
                  onSearch: onSearch,
                  animationController: animationController,
                ),
              ],
            ),
          ],
        ),
        ChatProfileInfoDetails(
          displayName: displayName,
          matrixId: matrixId,
          userInfo: userInfo,
          isBlockedUserNotifier: isBlockedUserNotifier,
          onUnblockUser: onUnblockUser,
          onBlockUser: onBlockUser,
          blockUserLoadingNotifier: blockUserLoadingNotifier,
          room: room,
          onLeaveChat: onLeaveChat,
        ),
      ],
    );
  }

  Widget _buildAvatarWidget({
    required UserInfo? userInfoModel,
    required AnimationController animationController,
  }) {
    if (userInfo.isLoading) {
      return SizedBox(
        width: double.infinity,
        height: ChatProfileInfoStyle.avatarHeight,
        child: Center(
          child: CupertinoActivityIndicator(
            animating: true,
            color: LinagoraSysColors.material().onSurfaceVariant,
          ),
        ),
      );
    }
    return SecondaryAvatar(
      mxContent: userInfoModel?.avatarUrl != null
          ? Uri.tryParse(userInfoModel?.avatarUrl ?? '')
          : avatarUri,
      name: userInfoModel?.displayName ?? displayName,
      fontSize: ChatProfileInfoStyle.avatarFontSize,
      animationController: animationController,
    );
  }
}

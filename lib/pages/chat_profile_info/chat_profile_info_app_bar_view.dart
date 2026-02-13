import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/user_info/get_user_info_state.dart';
import 'package:fluffychat/domain/model/user_info/user_info.dart';
import 'package:fluffychat/pages/chat_details/chat_details_group_actions_view.dart';
import 'package:fluffychat/pages/chat_details/chat_details_group_info_background_view.dart';
import 'package:fluffychat/pages/chat_details/chat_details_group_information_view.dart';
import 'package:fluffychat/pages/chat_profile_info/chat_profile_info_details.dart';
import 'package:fluffychat/pages/chat_profile_info/chat_profile_info_style.dart';
import 'package:fluffychat/widgets/avatar/secondary_avatar.dart';
import 'package:flutter/cupertino.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart' hide Contact;

class ChatProfileInfoAppBarView extends StatelessWidget {
  const ChatProfileInfoAppBarView({
    super.key,
    this.avatarUri,
    this.displayName,
    this.matrixId,
    required this.userInfoNotifier,
    required this.isDraftInfo,
    required this.isBlockedUserNotifier,
    this.onUnblockUser,
    this.onBlockUser,
    required this.blockUserLoadingNotifier,
    required this.isAlreadyInChat,
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
  final ValueNotifier<Either<Failure, Success>> userInfoNotifier;
  final bool isDraftInfo;
  final ValueNotifier<bool> isBlockedUserNotifier;
  final void Function()? onUnblockUser;
  final void Function()? onBlockUser;
  final ValueNotifier<bool?> blockUserLoadingNotifier;
  final bool isAlreadyInChat;
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
    return ValueListenableBuilder(
      valueListenable: userInfoNotifier,
      builder: (context, userInfo, child) {
        final userInfoModel = userInfo
            .getSuccessOrNull<GetUserInfoSuccess>()
            ?.userInfo;
        return Column(
          children: [
            Stack(
              children: [
                Positioned.fill(
                  child: _buildAvatarWidget(
                    context: context,
                    userInfo: userInfo,
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
                      displayName: _buildDisplayNameWidget(
                        context: context,
                        userInfo: userInfo,
                        userInfoModel: userInfoModel,
                      ),
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
              userInfoNotifier: userInfoNotifier,
              isAlreadyInChat: isAlreadyInChat,
              isBlockedUserNotifier: isBlockedUserNotifier,
              onUnblockUser: onUnblockUser,
              onBlockUser: onBlockUser,
              blockUserLoadingNotifier: blockUserLoadingNotifier,
              room: room,
              onLeaveChat: onLeaveChat,
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvatarWidget({
    required BuildContext context,
    required Either<Failure, Success> userInfo,
    required UserInfo? userInfoModel,
    required AnimationController animationController,
  }) {
    return userInfo.fold(
      (failure) {
        return SecondaryAvatar(
          mxContent: avatarUri,
          name: userInfoModel?.displayName ?? displayName,
          fontSize: ChatProfileInfoStyle.avatarFontSize,
          animationController: animationController,
        );
      },
      (success) {
        if (success is GettingUserInfo) {
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
        if (success is GetUserInfoSuccess) {
          return SecondaryAvatar(
            mxContent: userInfoModel?.avatarUrl != null
                ? Uri.parse(userInfoModel?.avatarUrl ?? '')
                : avatarUri,
            name: userInfoModel?.displayName ?? displayName,
            fontSize: ChatProfileInfoStyle.avatarFontSize,
            animationController: animationController,
          );
        }
        return SecondaryAvatar(
          mxContent: avatarUri,
          name: userInfoModel?.displayName ?? displayName,
          fontSize: ChatProfileInfoStyle.avatarFontSize,
          animationController: animationController,
        );
      },
    );
  }

  String? _buildDisplayNameWidget({
    required BuildContext context,
    required Either<Failure, Success> userInfo,
    required UserInfo? userInfoModel,
  }) {
    return userInfo.fold(
      (failure) {
        return displayName ?? '';
      },
      (success) {
        if (success is GettingUserInfo) {
          return null;
        }
        if (success is GetUserInfoSuccess) {
          return userInfoModel?.displayName ?? displayName ?? '';
        }
        return displayName ?? '';
      },
    );
  }
}

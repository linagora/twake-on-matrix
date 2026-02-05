import 'package:fluffychat/pages/chat_details/chat_details_view_style.dart';
import 'package:fluffychat/pages/chat_profile_info/chat_profile_info_app_bar.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

import 'package:fluffychat/pages/chat_profile_info/chat_profile_info.dart';
import 'package:fluffychat/pages/chat_profile_info/chat_profile_info_style.dart';

class ChatProfileInfoView extends StatelessWidget {
  final ChatProfileInfoController controller;

  const ChatProfileInfoView(
    this.controller, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final user = controller.user;
    final contact = controller.presentationContact;
    return Scaffold(
      backgroundColor: LinagoraSysColors.material().surfaceVariant,
      appBar: TwakeAppBar(
        backgroundColor: LinagoraSysColors.material().surfaceVariant,
        title: L10n.of(context)!.contactInfo,
        leading: IconButton(
          onPressed: controller.widget.onBack,
          icon: controller.widget.isInStack
              ? const Icon(
                  Icons.arrow_back_ios,
                )
              : const Icon(Icons.close),
        ),
        context: context,
      ),
      body: NestedScrollView(
        physics: controller.getScrollPhysics(),
        key: controller.nestedScrollViewState,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            ChatProfileInfoAppBar(
              userInfoNotifier: controller.userInfoNotifier,
              room: controller.room,
              user: user,
              presentationContact: contact,
              isAlreadyInChat: controller.isAlreadyInChat(context),
              tabList: controller.tabList,
              tabController: controller.tabController,
              isDraftInfo: controller.widget.isDraftInfo,
              isBlockedUserNotifier: controller.isBlockedUser,
              onUnblockUser: controller.onUnblockUser,
              onBlockUser: controller.onBlockUser,
              blockUserLoadingNotifier: controller.blockUserLoadingNotifier,
              onLeaveChat: controller.leaveChat,
              innerBoxIsScrolled: innerBoxIsScrolled,
              avatarUri: user?.avatarUrl,
              displayName: user?.calcDisplayname(),
              matrixId: user?.id,
              getLocalizedStatusMessage: controller.getLocalizedStatusMessage,
              onMessage: controller.handleOnMessage,
              onSearch: controller.handleOnSearch,
            ),
          ];
        },
        body: ClipRRect(
          borderRadius: BorderRadius.all(
            Radius.circular(
              ChatDetailViewStyle.chatDetailsPageViewWebBorderRadius,
            ),
          ),
          child: Container(
            width: ChatDetailViewStyle.chatDetailsPageViewWebWidth,
            padding: ChatDetailViewStyle.paddingTabBarView,
            decoration: ChatProfileInfoStyle.tabViewDecoration,
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              controller: controller.tabController,
              children: controller.sharedPages().map((page) {
                return page.child;
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

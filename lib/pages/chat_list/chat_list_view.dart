import 'package:twake_chat/pages/chat_list/chat_list.dart';
import 'package:twake_chat/pages/chat_list/chat_list_body_view.dart';
import 'package:twake_chat/pages/chat_list/chat_list_bottom_navigator.dart';
import 'package:twake_chat/pages/chat_list/chat_list_bottom_navigator_style.dart';
import 'package:twake_chat/pages/chat_list/chat_list_header.dart';
import 'package:twake_chat/pages/chat_list/chat_list_view_style.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

class ChatListView extends StatelessWidget {
  final ChatListController controller;
  final Widget? bottomNavigationBar;
  final VoidCallback? onOpenSearchPageInMultipleColumns;
  final ChatListBottomNavigatorBarIcon onTapBottomNavigation;

  const ChatListView({
    super.key,
    required this.controller,
    this.bottomNavigationBar,
    this.onOpenSearchPageInMultipleColumns,
    required this.onTapBottomNavigation,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.matrixState.voiceMessageEvent,
      builder: (context, hasEvent, child) {
        return Scaffold(
          backgroundColor: LinagoraSysColors.material().onPrimary,
          appBar: PreferredSize(
            preferredSize: ChatListViewStyle.preferredSizeAppBar(
              hasAudioEvent: hasEvent != null && PlatformInfos.isMobile,
            ),
            child: ChatListHeader(
              onOpenSearchPageInMultipleColumns:
                  onOpenSearchPageInMultipleColumns,
              controller: controller,
            ),
          ),
          bottomNavigationBar: ValueListenableBuilder(
            valueListenable: controller.conversationSelectionNotifier,
            builder: (context, conversationSelection, __) {
              if (conversationSelection.isNotEmpty) {
                return ChatListBottomNavigator(
                  bottomNavigationActionsWidget: controller
                      .bottomNavigationActionsWidget(
                        paddingIcon: ChatListBottomNavigatorStyle.paddingIcon,
                        iconSize: ChatListBottomNavigatorStyle.iconSize,
                        width: ChatListBottomNavigatorStyle.width,
                      ),
                );
              } else {
                return bottomNavigationBar ?? const SizedBox();
              }
            },
          ),
          body: StreamBuilder<Client>(
            stream: controller.clientStream,
            builder: (context, snapshot) {
              return ChatListBodyView(controller);
            },
          ),
        );
      },
    );
  }
}

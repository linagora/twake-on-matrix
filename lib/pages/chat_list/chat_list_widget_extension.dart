import 'package:badges/badges.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/chat_list_body_stream.dart';
import 'package:fluffychat/pages/chat_list/chat_list_header.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_appbar.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab_body_view.dart';
import 'package:fluffychat/widgets/twake_components/twake_fab.dart';
import 'package:fluffychat/widgets/unread_rooms_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:keyboard_shortcuts/keyboard_shortcuts.dart';
import 'package:vrouter/vrouter.dart';

extension ChatListExtension on ChatListController {

  List<NavigationDestination> getNavigationDestinations(BuildContext context) {
    final badgePosition = BadgePosition.topEnd(top: -12, end: -8);
    return [
      if (AppConfig.separateChatTypes) ...[
        NavigationDestination(
          icon: const Icon(Icons.contacts_outlined),
          label: L10n.of(context)!.contacts,
        ),
        NavigationDestination(
          icon: UnreadRoomsBadge(
            badgePosition: badgePosition,
            filter: getRoomFilterByActiveFilter(ActiveFilter.messages),
            child: const Icon(Icons.chat),
          ),
          label: L10n.of(context)!.chat,
        ),
        NavigationDestination(
          icon: const Icon(Icons.web_stories_outlined),
          label: L10n.of(context)!.stories,
        ),
      ] else
        NavigationDestination(
          icon: UnreadRoomsBadge(
            badgePosition: badgePosition,
            filter: getRoomFilterByActiveFilter(ActiveFilter.allChats),
            child: const Icon(Icons.chat_outlined),
          ),
          label: L10n.of(context)!.chats,
        ),
      if (spaces.isNotEmpty)
        const NavigationDestination(
          icon: Icon(Icons.workspaces_outlined),
          selectedIcon: Icon(Icons.workspaces),
          label: 'Spaces',
        ),
    ];
  }

  PreferredSizeWidget buildAppBar() {
    switch (activeBottomTabbar) {
      case BottomTabbar.chats:
        return ChatListHeader(controller: this);
      case BottomTabbar.contacts:
        return ContactsAppBar(controller: this);
      case BottomTabbar.stories:
        return AppBar(title: const Text("Stories"),);
    }
  }

  Widget buildBody() {
    switch (activeBottomTabbar) {
      case BottomTabbar.chats:
        return ChatListBodyStream(controller: this);
      case BottomTabbar.contacts:
        return ContactsTabBodyView(this);
      case BottomTabbar.stories:
        return const Center(child: Text("Stories"),);
    }
  }

  Widget? buildFloatingButton() {
    switch (activeBottomTabbar) {
      case BottomTabbar.chats:
        return selectMode == SelectMode.normal
          ? KeyBoardShortcuts(
              keysToPress: {
                LogicalKeyboardKey.controlLeft,
                LogicalKeyboardKey.keyN
              },
              onKeysPressed: () =>
                  VRouter.of(context).to('/newprivatechat'),
              helpLabel: L10n.of(context)!.newChat,
              child: TwakeFloatingActionButton(
                icon: Icons.mode_edit_outline_outlined,
                onTap: () => VRouter.of(context).to('/newprivatechat'),
              ),
            )
          : null;
      case BottomTabbar.contacts:
      case BottomTabbar.stories:
        return null;
    }
  }

}
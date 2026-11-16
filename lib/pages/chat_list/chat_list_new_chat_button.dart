import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keyboard_shortcuts/keyboard_shortcuts.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_list/chat_list.dart';
import 'package:twake_chat/pages/chat_list/chat_list_view_style.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/mixins/popup_menu_widget_style.dart';

/// The pen of the app bar: a bare icon, no container. Opens the menu of new
/// chats on wide layouts (below the pen, flipped to its left by MenuAnchor if
/// it would leave the screen), the new direct message on a single column.
class ChatListNewChatButton extends StatelessWidget {
  final ChatListController controller;

  const ChatListNewChatButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final isSingleColumn = getIt.get<ResponsiveUtils>().isSingleColumnLayout(
      context,
    );
    Widget pen(VoidCallback onPressed) => IconButton(
      key: const Key('new_chat_pen'),
      tooltip: l10n.newChat,
      iconSize: ChatListViewStyle.editIconSize,
      icon: const Icon(Icons.mode_edit_outline_outlined),
      onPressed: onPressed,
    );
    TextStyle? textStyle() =>
        PopupMenuWidgetStyle.defaultItemTextStyle(context);
    return KeyBoardShortcuts(
      keysToPress: {LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyN},
      onKeysPressed: () => controller.goToNewPrivateChat(),
      helpLabel: l10n.newChat,
      child: isSingleColumn
          ? pen(controller.goToNewPrivateChat)
          : MenuAnchor(
              menuChildren: [
                MenuItemButton(
                  leadingIcon: const Icon(Icons.chat),
                  onPressed: () => controller.goToNewPrivateChat(),
                  child: Text(l10n.newDirectMessage, style: textStyle()),
                ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.group),
                  onPressed: () => controller.goToNewGroupChat(context),
                  child: Text(l10n.newGroupChat, style: textStyle()),
                ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.campaign_outlined),
                  onPressed: () => controller.goToNewFeed(context),
                  child: Text(l10n.newFeed, style: textStyle()),
                ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.view_in_ar),
                  onPressed: () => controller.goToNewSpace(context),
                  child: Text(l10n.newSpace, style: textStyle()),
                ),
              ],
              style: MenuStyle(
                alignment: Alignment.topLeft,
                backgroundColor: WidgetStatePropertyAll(
                  PopupMenuWidgetStyle.defaultMenuColor(context),
                ),
              ),
              builder: (context, menuController, child) =>
                  pen(menuController.open),
            ),
    );
  }
}

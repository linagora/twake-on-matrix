import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/chat_list_body_stream.dart';
import 'package:fluffychat/pages/chat_list/chat_list_header.dart';
import 'package:fluffychat/pages/chat_list/chat_list_view_style.dart';
import 'package:fluffychat/widgets/twake_components/twake_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:keyboard_shortcuts/keyboard_shortcuts.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class ChatListView extends StatelessWidget {
  final ChatListController controller;
  final Widget? bottomNavigationBar;
  final Function()? onTapSearch;

  const ChatListView({
    Key? key,
    required this.controller,
    this.bottomNavigationBar,
    this.onTapSearch,
  }) : super(key: key);

  static const ValueKey bottomNavigationKey = ValueKey('BottomNavigation');

  static const ValueKey primaryNavigationKey =
      ValueKey('AdaptiveScaffoldPrimaryNavigation');

  static const ValueKey contacts = ValueKey('Contacts');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: ChatListViewStyle.preferredSizeAppBar(context),
        child: ChatListHeader(
          controller: controller,
          onTapSearch: onTapSearch,
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
      body: ChatListBodyStream(controller: controller),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: controller.selectMode == SelectMode.normal
          ? KeyBoardShortcuts(
              keysToPress: {
                LogicalKeyboardKey.controlLeft,
                LogicalKeyboardKey.keyN
              },
              onKeysPressed: () => context.go('/rooms/newprivatechat'),
              helpLabel: L10n.of(context)!.newChat,
              child: TwakeFloatingActionButton(
                icon: Icons.mode_edit_outline_outlined,
                size: 18.0,
                onTap: () => context.go('/rooms/newprivatechat'),
              ),
            )
          : null,
    );
  }
}

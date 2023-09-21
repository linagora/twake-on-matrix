import 'package:fluffychat/pages/chat_list/chat_list_bottom_navigator_style.dart';
import 'package:fluffychat/presentation/enum/chat_list/chat_list_enum.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

typedef ChatListBottomNavigatorBarIcon = Function(ChatListSelectionActions);

class ChatListBottomNavigator extends StatelessWidget {
  final List<Widget> bottomNavigationActionsWidget;

  const ChatListBottomNavigator({
    super.key,
    required this.bottomNavigationActionsWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ResponsiveUtils.heightBottomNavigation,
      padding: ChatListBottomNavigatorStyle.padding,
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: bottomNavigationActionsWidget,
      ),
    );
  }
}

import 'package:twake_chat/pages/chat_list/chat_list_bottom_navigator_style.dart';
import 'package:twake_chat/presentation/enum/chat_list/chat_list_enum.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
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

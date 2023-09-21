import 'package:fluffychat/pages/chat_list/chat_list_bottom_navigator_style.dart';
import 'package:fluffychat/presentation/enum/chat_list/chat_list_enum.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

typedef ChatListBottomNavigatorBarIcon = Function(ChatListSelectionActions);

class ChatListBottomNavigator extends StatelessWidget {
  const ChatListBottomNavigator({
    super.key,
    required this.onTapBottomNavigation,
  });

  final ChatListBottomNavigatorBarIcon onTapBottomNavigation;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ResponsiveUtils.heightBottomNavigation,
      padding: ChatListBottomNavigatorStyle.padding,
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _getNavigationDestinations.map(
          (item) {
            return InkWell(
              onTap: () => onTapBottomNavigation(item),
              child: SizedBox(
                width: ChatListBottomNavigatorStyle.width,
                child: Column(
                  children: [
                    Padding(
                      padding: ChatListBottomNavigatorStyle.paddingIcon,
                      child: Icon(
                        item.getIcon(context),
                        size: ChatListBottomNavigatorStyle.iconSize,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      item.getTitleForMobile(context),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  List<ChatListSelectionActions> get _getNavigationDestinations {
    return [
      ChatListSelectionActions.read,
      ChatListSelectionActions.mute,
      ChatListSelectionActions.pin,
      ChatListSelectionActions.more,
    ];
  }
}

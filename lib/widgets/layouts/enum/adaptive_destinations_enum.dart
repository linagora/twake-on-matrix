import 'package:fluffychat/utils/matrix_sdk_extensions/client_stories_extension.dart';
import 'package:fluffychat/widgets/avatar/bottom_navigation_avatar.dart';
import 'package:fluffychat/widgets/twake_components/twake_navigation_icon/twake_navigation_icon.dart';
import 'package:fluffychat/widgets/unread_rooms_badge.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

enum AdaptiveDestinationEnum {
  contacts,
  rooms,
  settings;

  NavigationDestination getNavigationDestination(
    BuildContext context,
    ValueNotifier<Profile?> profile,
  ) {
    switch (this) {
      case AdaptiveDestinationEnum.contacts:
        return NavigationDestination(
          icon: TwakeNavigationIcon(
            color: LinagoraSysColors.material().onBackground,
            icon: Icons.supervised_user_circle_outlined,
          ),
          label: L10n.of(context)!.contacts,
          selectedIcon: const TwakeNavigationIcon(
            icon: Icons.supervised_user_circle_outlined,
            isSelected: true,
          ),
        );
      case AdaptiveDestinationEnum.rooms:
        return NavigationDestination(
          icon: UnreadRoomsBadge(
            color: LinagoraSysColors.material().onBackground,
            filter: (room) => !room.isSpace && !room.isStoryRoom,
          ),
          selectedIcon: UnreadRoomsBadge(
            filter: (room) => !room.isSpace && !room.isStoryRoom,
            isSelected: true,
          ),
          label: L10n.of(context)!.chats,
        );
      case AdaptiveDestinationEnum.settings:
        return NavigationDestination(
          icon: TwakeNavigationIcon(
            color: LinagoraSysColors.material().onBackground,
            icon: Icons.settings_outlined,
          ),
          selectedIcon: const TwakeNavigationIcon(
            icon: Icons.settings_outlined,
            isSelected: true,
          ),
          label: L10n.of(context)!.settings,
        );
    }
  }

  BottomNavigationBarItem getNavigationDestinationForBottomBar(
    BuildContext context,
    ValueNotifier<Profile?> profile,
  ) {
    switch (this) {
      case AdaptiveDestinationEnum.contacts:
        return BottomNavigationBarItem(
          icon: TwakeNavigationIcon(
            color: LinagoraSysColors.material().tertiary,
            icon: Icons.supervised_user_circle_outlined,
          ),
          label: L10n.of(context)!.contacts,
          activeIcon: const TwakeNavigationIcon(
            icon: Icons.supervised_user_circle_outlined,
            isSelected: true,
          ),
        );
      case AdaptiveDestinationEnum.rooms:
        return BottomNavigationBarItem(
          icon: UnreadRoomsBadge(
            color: LinagoraSysColors.material().tertiary,
            filter: (room) => !room.isSpace && !room.isStoryRoom,
          ),
          activeIcon: UnreadRoomsBadge(
            filter: (room) => !room.isSpace && !room.isStoryRoom,
            isSelected: true,
          ),
          label: L10n.of(context)!.chats,
        );
      case AdaptiveDestinationEnum.settings:
        return BottomNavigationBarItem(
          icon: BottomNavigationAvatar(
            profile: profile,
            isSelected: false,
          ),
          activeIcon: BottomNavigationAvatar(
            profile: profile,
            isSelected: true,
          ),
          label: L10n.of(context)!.settings,
        );
    }
  }
}

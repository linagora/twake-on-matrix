import 'package:twake_chat/pages/activity/activity_navigation_icon.dart';
import 'package:twake_chat/presentation/widget_keys/widget_keys.dart';
import 'package:twake_chat/domain/model/room/room_extension.dart';
import 'package:twake_chat/widgets/twake_components/twake_navigation_icon/twake_navigation_icon.dart';
import 'package:twake_chat/widgets/unread_rooms_badge.dart';
import 'package:flutter/material.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

enum AdaptiveDestinationEnum {
  contacts,
  rooms,
  activity,
  settings;

  NavigationDestination getNavigationDestination(
    BuildContext context,
    ValueNotifier<Profile?> profile,
  ) {
    switch (this) {
      case AdaptiveDestinationEnum.contacts:
        return NavigationDestination(
          key: NavigationKeys.contactsDestination.key,
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
          key: NavigationKeys.roomsDestination.key,
          icon: UnreadRoomsBadge(
            color: LinagoraSysColors.material().onBackground,
            filter: (room) => room.isNotSpaceAndStoryRoom(),
          ),
          selectedIcon: UnreadRoomsBadge(
            filter: (room) => room.isNotSpaceAndStoryRoom(),
            isSelected: true,
          ),
          label: L10n.of(context)!.chats,
        );
      case AdaptiveDestinationEnum.activity:
        return NavigationDestination(
          key: NavigationKeys.activityDestination.key,
          icon: ActivityNavigationIcon(
            color: LinagoraSysColors.material().onBackground,
          ),
          selectedIcon: const ActivityNavigationIcon(isSelected: true),
          label: L10n.of(context)!.activity,
        );
      case AdaptiveDestinationEnum.settings:
        return NavigationDestination(
          key: NavigationKeys.settingsDestination.key,
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

  Key get navigationKey => switch (this) {
    AdaptiveDestinationEnum.contacts => NavigationKeys.contactsDestination.key,
    AdaptiveDestinationEnum.rooms => NavigationKeys.roomsDestination.key,
    AdaptiveDestinationEnum.activity => NavigationKeys.activityDestination.key,
    AdaptiveDestinationEnum.settings => NavigationKeys.settingsDestination.key,
  };

  String label(L10n l10n) => switch (this) {
    AdaptiveDestinationEnum.contacts => l10n.contacts,
    AdaptiveDestinationEnum.rooms => l10n.chats,
    AdaptiveDestinationEnum.activity => l10n.activity,
    AdaptiveDestinationEnum.settings => l10n.settings,
  };

  Widget floatingBarIcon({required bool isSelected, required Color color}) =>
      switch (this) {
        AdaptiveDestinationEnum.contacts => TwakeNavigationIcon(
          icon: Icons.people,
          isSelected: isSelected,
          color: color,
        ),
        AdaptiveDestinationEnum.rooms => UnreadRoomsBadge(
          filter: (room) => room.isNotSpaceAndStoryRoom(),
          isSelected: isSelected,
          color: color,
        ),
        AdaptiveDestinationEnum.activity => ActivityNavigationIcon(
          icon: Icons.notifications,
          isSelected: isSelected,
          color: color,
        ),
        AdaptiveDestinationEnum.settings => TwakeNavigationIcon(
          icon: Icons.settings,
          isSelected: isSelected,
          color: color,
        ),
      };
}

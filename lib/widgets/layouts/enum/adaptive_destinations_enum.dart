import 'package:fluffychat/utils/matrix_sdk_extensions/client_stories_extension.dart';
import 'package:fluffychat/widgets/twake_components/twake_navigation_icon/twake_navigation_icon.dart';
import 'package:fluffychat/widgets/unread_rooms_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

enum AdaptiveDestinationEnum {
  contacts,
  rooms,
  settings;

  NavigationDestination getNavigationDestination(BuildContext context) {
    switch (this) {
      case AdaptiveDestinationEnum.contacts:
        return NavigationDestination(
          icon: const TwakeNavigationIcon(
            icon: Icons.contacts_outlined,
          ),
          label: L10n.of(context)!.contacts,
        );
      case AdaptiveDestinationEnum.rooms:
        return NavigationDestination(
          icon: UnreadRoomsBadge(
            filter: (room) => !room.isSpace && !room.isStoryRoom,
          ),
          label: L10n.of(context)!.chats,
        );
      case AdaptiveDestinationEnum.settings:
        return NavigationDestination(
          icon: const TwakeNavigationIcon(
            icon: Icons.settings,
          ),
          label: L10n.of(context)!.settings,
        );
      default:
        return NavigationDestination(
          icon: UnreadRoomsBadge(
            filter: (room) => !room.isSpace && !room.isStoryRoom,
          ),
          label: L10n.of(context)!.chats,
        );
    }
  }
}

import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/client_stories_extension.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/avatar/bottom_navigation_avatar.dart';
import 'package:fluffychat/widgets/twake_components/twake_navigation_icon/twake_navigation_icon.dart';
import 'package:fluffychat/widgets/unread_rooms_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

enum AdaptiveDestinationEnum {
  contacts,
  rooms,
  settings;

  static final _responsive = getIt.get<ResponsiveUtils>();

  NavigationDestination getNavigationDestination(
    BuildContext context,
    ValueNotifier<Profile?> profile,
  ) {
    switch (this) {
      case AdaptiveDestinationEnum.contacts:
        return NavigationDestination(
          icon: TwakeNavigationIcon(
            color: !_responsive.isDesktop(context)
                ? LinagoraSysColors.material().tertiary
                : LinagoraSysColors.material().onBackground,
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
            color: !_responsive.isDesktop(context)
                ? LinagoraSysColors.material().tertiary
                : LinagoraSysColors.material().onBackground,
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
          icon: !_responsive.isDesktop(context)
              ? BottomNavigationAvatar(
                  profile: profile,
                  isSelected: false,
                )
              : TwakeNavigationIcon(
                  color: !_responsive.isDesktop(context)
                      ? LinagoraSysColors.material().tertiary
                      : LinagoraSysColors.material().onBackground,
                  icon: Icons.settings_outlined,
                ),
          selectedIcon: !_responsive.isDesktop(context)
              ? BottomNavigationAvatar(profile: profile, isSelected: true)
              : const TwakeNavigationIcon(
                  icon: Icons.settings_outlined,
                  isSelected: true,
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

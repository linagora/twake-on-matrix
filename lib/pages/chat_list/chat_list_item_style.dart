import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

class ChatListItemStyle {
  static Color? get readIconColor => LinagoraRefColors.material().tertiary[20];

  static Color? get pinnedIconColor =>
      LinagoraRefColors.material().tertiary[40];

  static const double readIconSize = 20;

  static const double groupIconSize = 16;

  static const double mentionIconWidth = 20;

  static const double chatItemHeight = 80;

  static double unreadBadgeSize(
    bool unread,
    bool hasNewMessages,
    bool hasNotifications,
  ) {
    return unread || hasNewMessages
        ? hasNotifications
            ? 20.0
            : 14.0
        : 0.0;
  }

  static const EdgeInsets paddingConversation = EdgeInsets.fromLTRB(
    8,
    8,
    8,
    8,
  );

  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: 8,
  );

  static const EdgeInsetsDirectional paddingAvatar =
      EdgeInsetsDirectional.only(end: 8);

  static const EdgeInsetsDirectional paddingIconGroup =
      EdgeInsetsDirectional.all(4);

  static const EdgeInsetsDirectional paddingBody = EdgeInsetsDirectional.all(8);

  static const double unreadBadgePaddingWhenMoreThanOne = 9.0;

  static double notificationBadgeSize(
    bool unread,
    bool hasNewMessages,
    int notificationCount,
  ) {
    return notificationCount == 0 && !unread && !hasNewMessages
        ? 0
        : (unreadBadgeSize(unread, hasNewMessages, notificationCount > 0) -
                    unreadBadgePaddingWhenMoreThanOne) *
                notificationCount.toString().length +
            unreadBadgePaddingWhenMoreThanOne;
  }

  static const double letterSpaceDisplayName = 0.15;

  static final chatlistItemBorderRadius = BorderRadius.circular(4);

  static const paddingIcon = EdgeInsets.only(bottom: 4);

  static const chatListBottomBorderWidht = 1.0;
}

import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

class ChatListItemStyle {
  static Color? get readIconColor => LinagoraRefColors.material().tertiary[20];

  static Color? get pinnedIconColor =>
      LinagoraRefColors.material().tertiary[40];

  static const double readIconSize = 20;

  static const double groupIconSize = 16;

  static const double mentionIconWidth = 20;

  static const double chatItemHeight = 72;

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

  static const EdgeInsets paddingConversation = EdgeInsets.fromLTRB(8, 8, 8, 8);

  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 8);

  static const EdgeInsetsDirectional paddingAvatar = EdgeInsetsDirectional.only(
    end: 8,
  );

  static const EdgeInsetsDirectional paddingIconGroup =
      EdgeInsetsDirectional.all(4);

  static const EdgeInsetsDirectional paddingBody =
      EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 4);

  static const double unreadBadgePaddingWhenMoreThanOne = 9.0;

  static double notificationBadgeSize(
    bool unread,
    bool hasNewMessages,
    int notificationCount,
  ) {
    // No badge if no new messages and not marked unread
    if (!hasNewMessages && !unread) {
      return 0;
    }

    // If there's a notification count, calculate badge size for the number
    if (notificationCount > 0) {
      return (unreadBadgeSize(unread, hasNewMessages, true) -
                  unreadBadgePaddingWhenMoreThanOne) *
              notificationCount.toString().length +
          unreadBadgePaddingWhenMoreThanOne;
    }

    // If has new messages but no notification count (e.g., mentions-only room with regular messages)
    // or marked unread, show small badge (14.0 size, no number)
    if (hasNewMessages || unread) {
      return unreadBadgeSize(unread, hasNewMessages, false);
    }

    return 0;
  }

  static const double letterSpaceDisplayName = 0.15;

  static final chatlistItemBorderRadius = BorderRadius.circular(4);

  static const paddingIcon = EdgeInsets.only(bottom: 4);

  static const chatListBottomBorderWidht = 1.0;
}

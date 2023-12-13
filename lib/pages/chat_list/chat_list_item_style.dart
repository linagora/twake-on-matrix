import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

class ChatListItemStyle {
  static Color? get readIconColor => LinagoraRefColors.material().tertiary[20];

  static double readIconSize = 20.r;

  static double groupIconSize = 16.r;

  static double mentionIconWidth = 20.w;

  static double chatItemHeight = 96.h;

  static double unreadBadgeSize(
    bool unread,
    bool hasNewMessages,
    bool hasNotifications,
  ) {
    return unread || hasNewMessages
        ? hasNotifications
            ? 20.0.h
            : 14.0.h
        : 0.0;
  }

  static EdgeInsetsDirectional paddingConversation =
      EdgeInsetsDirectional.symmetric(
    horizontal: 8.w,
    vertical: 2.h,
  );

  static EdgeInsetsDirectional paddingAvatar =
      EdgeInsetsDirectional.only(end: 8.w);

  static EdgeInsetsDirectional paddingIconGroup =
      EdgeInsetsDirectional.all(4.w);

  static EdgeInsetsDirectional paddingBody = EdgeInsetsDirectional.all(8.h);

  static double unreadBadgePaddingWhenMoreThanOne = 9.0.w;

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
}

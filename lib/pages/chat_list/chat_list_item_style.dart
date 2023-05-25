import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

class ChatListItemStyle {
  static Color? get readIconColor => LinagoraRefColors.material().tertiary[20];
  static double get readIconSize => 16;
  static double get editIconSize => 14;
  static double get mentionIconWidth => 20;
  static Color get readMessageColor => const Color(0xFF787579);
  static double unreadBadgeSize(bool unread, bool hasNewMessages, bool hasNotifications) {
    return unread || hasNewMessages
        ? hasNotifications
            ? 20.0
            : 14.0
        : 0.0;
  }

  static const double unreadBadgePaddingWhenMoreThanOne = 9.0;
  static double notificationBadgeSize(bool unread, bool hasNewMessages, int notificationCount) {
    return notificationCount == 0 && !unread && !hasNewMessages
        ? 0
        : (unreadBadgeSize(unread, hasNewMessages, notificationCount > 0) -
                    unreadBadgePaddingWhenMoreThanOne) *
                notificationCount.toString().length +
            unreadBadgePaddingWhenMoreThanOne;
  }

  static double get isTypingFontSize => 15;
  static double get lastSenderFontSize => 14;
}

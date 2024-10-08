import 'package:collection/collection.dart';
import 'package:fluffychat/widgets/twake_components/twake_navigation_icon/twake_navigation_icon.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'matrix.dart';

class UnreadRoomsBadge extends StatelessWidget {
  final bool Function(Room) filter;
  final bool isSelected;
  final Color? color;

  const UnreadRoomsBadge({
    super.key,
    required this.filter,
    this.isSelected = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Matrix.of(context)
          .client
          .onSync
          .stream
          .where((syncUpdate) => syncUpdate.hasRoomUpdate),
      builder: (context, _) {
        final unreadCount = getNotificationsCount(context);

        return TwakeNavigationIcon(
          icon: Icons.chat_bubble,
          notificationCount: unreadCount,
          isSelected: isSelected,
          color: color,
        );
      },
    );
  }

  int getNotificationsCount(BuildContext context) {
    return Matrix.of(context)
        .client
        .rooms
        .where(filter)
        .where((r) => (r.isUnread || r.membership == Membership.invite))
        .map((element) => element.isUnread ? element.notificationCount : 1)
        .sum;
  }
}

import 'package:twake_chat/utils/thread_unread/thread_unread_store.dart';
import 'package:collection/collection.dart';
import 'package:twake_chat/presentation/extensions/client_extension.dart';
import 'package:twake_chat/widgets/twake_components/twake_navigation_icon/twake_navigation_icon.dart';
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
      stream: Matrix.of(
        context,
      ).client.onSync.stream.where((syncUpdate) => syncUpdate.hasRoomUpdate),
      builder: (context, _) => ListenableBuilder(
        listenable: Listenable.merge([?Matrix.of(context).client.threadUnread]),
        builder: (context, _) => TwakeNavigationIcon(
          icon: Icons.chat_bubble,
          notificationCount: getNotificationsCount(context),
          isSelected: isSelected,
          color: color,
        ),
      ),
    );
  }

  int getNotificationsCount(BuildContext context) =>
      countNotifications(Matrix.of(context).client, filter);

  @visibleForTesting
  static int countNotifications(Client client, bool Function(Room) filter) {
    return client.joinedOrInvitedRooms
        .where(filter)
        .where(
          (r) => (r.isUnreadWithThreads || r.membership == Membership.invite),
        )
        .map(
          (element) =>
              element.isUnreadWithThreads ? element.unreadBadgeCount : 1,
        )
        .sum;
  }
}

import 'package:twake_chat/utils/thread_unread/thread_unread_store.dart';
import 'package:collection/collection.dart';
import 'package:twake_chat/presentation/extensions/client_extension.dart';
import 'package:twake_chat/widgets/twake_components/twake_navigation_icon/twake_navigation_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/providers/matrix_client_provider.dart';

class UnreadRoomsBadge extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(matrixClientProvider);
    return StreamBuilder(
      stream: client.onSync.stream.where(
        (syncUpdate) => syncUpdate.hasRoomUpdate,
      ),
      builder: (context, _) => ListenableBuilder(
        listenable: Listenable.merge([?client.threadUnread]),
        builder: (context, _) => TwakeNavigationIcon(
          icon: Icons.chat_bubble,
          notificationCount: countNotifications(client, filter),
          isSelected: isSelected,
          color: color,
        ),
      ),
    );
  }

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

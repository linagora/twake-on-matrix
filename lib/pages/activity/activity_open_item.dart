import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

/// Opens what [item] is about: the room, the thread, or the message in them.
/// A pushed screen returns to the tab on back; on a wide layout a room
/// replaces the page, which the filter controller restores.
void openActivityItem(BuildContext context, ActivityItem item) {
  final rootId = item.threadRootId;
  final GoRouteData route = switch (item.kind) {
    ActivityKind.unreadRoom => RoomRoute(roomid: item.roomId),
    ActivityKind.reply => ThreadRoute(roomid: item.roomId, rootid: rootId!),
    ActivityKind.mention || ActivityKind.reaction =>
      rootId == null
          ? RoomRoute(roomid: item.roomId, event: item.eventId)
          : ThreadRoute(
              roomid: item.roomId,
              rootid: rootId,
              event: item.eventId,
            ),
  };
  // A thread is a full screen above its room, whatever the layout.
  if (route is ThreadRoute || ResponsiveUtils().isSingleColumnLayout(context)) {
    route.push<void>(context);
  } else {
    route.go(context);
  }
}

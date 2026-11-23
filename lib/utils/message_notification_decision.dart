import 'package:twake_chat/domain/matrix_events/event_type_rules.dart';

/// What the notification decision needs to know about an incoming event.
class MessageNotificationCandidate {
  const MessageNotificationCandidate({
    required this.roomId,
    required this.senderId,
    required this.ownUserId,
    required this.eventType,
    required this.notificationCount,
    required this.highlightCount,
    required this.isRoomMuted,
    required this.activeRoomId,
    required this.appInForeground,
  });

  final String roomId;
  final String senderId;
  final String? ownUserId;
  final String eventType;
  final int notificationCount;
  final int highlightCount;
  final bool isRoomMuted;
  final String? activeRoomId;
  final bool appInForeground;
}

/// Whether the desktop should show a local notification for [c].
bool shouldNotifyMessage(MessageNotificationCandidate c) {
  if (!EventTypeRules.messageContentTypes.contains(c.eventType)) return false;
  if (c.senderId == c.ownUserId) return false;
  if (c.appInForeground && c.activeRoomId == c.roomId) return false;
  if (c.notificationCount == 0) return false;
  return !c.isRoomMuted || c.highlightCount > 0;
}

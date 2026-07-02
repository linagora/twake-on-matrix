import 'package:fluffychat/pages/chat/events/message_time_style.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

enum MessageStatus { sending, sent, hasBeenSeen, error }

class SeenByRow extends StatelessWidget {
  final List<User> getSeenByUsers;
  final EventStatus? eventStatus;
  final bool timelineOverlayMessage;

  final double size;

  const SeenByRow({
    this.eventStatus,
    super.key,
    required this.getSeenByUsers,
    required this.timelineOverlayMessage,
    this.size = MessageTimeStyle.seenByRowIconSize,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return getEventIcon(colorScheme, getSeenByUsers, eventStatus: eventStatus);
  }

  MessageStatus getMessageStatus(
    List<User> seenByUsers, {
    EventStatus? eventStatus,
  }) {
    if (eventStatus == EventStatus.error) {
      return MessageStatus.error;
    }

    if (eventStatus == null || eventStatus == EventStatus.sending) {
      return MessageStatus.sending;
    }

    if (eventStatus == EventStatus.sent || seenByUsers.isEmpty) {
      return MessageStatus.sent;
    }

    return MessageStatus.hasBeenSeen;
  }

  Widget getEventIcon(
    ColorScheme colorScheme,
    List<User> seenByUsers, {
    EventStatus? eventStatus,
  }) {
    final Color secondaryColor = MessageTimeStyle.seenByRowIconSecondaryColor(
      timelineOverlayMessage,
      colorScheme,
    );
    final (IconData icon, Color color) = switch (getMessageStatus(
      seenByUsers,
      eventStatus: eventStatus,
    )) {
      MessageStatus.sending => (Icons.schedule, secondaryColor),
      MessageStatus.sent => (Icons.done_all, secondaryColor),
      MessageStatus.hasBeenSeen => (
        Icons.done_all,
        MessageTimeStyle.seenByRowIconPrimaryColor(timelineOverlayMessage),
      ),
      MessageStatus.error => (Icons.error, colorScheme.error),
    };
    return Icon(icon, color: color, size: size);
  }
}

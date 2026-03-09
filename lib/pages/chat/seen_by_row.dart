import 'package:fluffychat/pages/chat/events/message_time_style.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

enum MessageStatus { sending, sent, hasBeenSeen, error }

class SeenByRow extends StatelessWidget {
  final List<User> getSeenByUsers;
  final EventStatus? eventStatus;
  final bool timelineOverlayMessage;

  const SeenByRow({
    this.eventStatus,
    super.key,
    required this.getSeenByUsers,
    required this.timelineOverlayMessage,
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
    final messageStatus = getMessageStatus(
      seenByUsers,
      eventStatus: eventStatus,
    );
    switch (messageStatus) {
      case MessageStatus.sending:
        return Icon(
          Icons.schedule,
          color: MessageTimeStyle.seenByRowIconSecondaryColor(
            timelineOverlayMessage,
            colorScheme,
          ),
          size: MessageTimeStyle.seenByRowIconSize,
        );
      case MessageStatus.sent:
        return Icon(
          Icons.done_all,
          color: MessageTimeStyle.seenByRowIconSecondaryColor(
            timelineOverlayMessage,
            colorScheme,
          ),
          size: MessageTimeStyle.seenByRowIconSize,
        );
      case MessageStatus.hasBeenSeen:
        return Icon(
          Icons.done_all,
          color: MessageTimeStyle.seenByRowIconPrimaryColor(
            timelineOverlayMessage,
          ),
          size: MessageTimeStyle.seenByRowIconSize,
        );
      case MessageStatus.error:
        return Icon(
          Icons.error,
          color: colorScheme.error,
          size: MessageTimeStyle.seenByRowIconSize,
        );
    }
  }
}

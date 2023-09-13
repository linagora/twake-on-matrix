import 'package:fluffychat/pages/chat/events/message_time_style.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

enum MessageStatus {
  sending,
  sent,
  hasBeenSeen,
  error,
}

class SeenByRow extends StatelessWidget {
  final List<User> getSeenByUsers;
  final List<User> participants;
  final EventStatus? eventStatus;
  final bool timelineOverlayMessage;

  const SeenByRow({
    this.eventStatus,
    Key? key,
    required this.getSeenByUsers,
    required this.participants,
    required this.timelineOverlayMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return getEventIcon(context, eventStatus, getSeenByUsers);
  }

  MessageStatus getMessageStatus(
    BuildContext context,
    EventStatus? eventStatus,
    List<User> seenByUsers,
  ) {
    if (eventStatus == null || eventStatus == EventStatus.sending) {
      return MessageStatus.sending;
    }

    if (eventStatus == EventStatus.sent || seenByUsers.isEmpty) {
      return MessageStatus.sent;
    }

    if (eventStatus == EventStatus.error) {
      return MessageStatus.error;
    }

    return MessageStatus.hasBeenSeen;
  }

  Widget getEventIcon(
    BuildContext context,
    EventStatus? eventStatus,
    List<User> seenByUsers,
  ) {
    final messageStatus = getMessageStatus(context, eventStatus, seenByUsers);
    switch (messageStatus) {
      case MessageStatus.sending:
        return Icon(
          Icons.schedule,
          color: MessageTimeStyle.seenByRowIconSecondaryColor(
            timelineOverlayMessage,
            context,
          ),
          size: MessageTimeStyle.seenByRowIconSize,
        );
      case MessageStatus.sent:
        return Icon(
          Icons.done_all,
          color: MessageTimeStyle.seenByRowIconSecondaryColor(
            timelineOverlayMessage,
            context,
          ),
          size: MessageTimeStyle.seenByRowIconSize,
        );
      case MessageStatus.hasBeenSeen:
        return Icon(
          Icons.done_all,
          color: MessageTimeStyle.seenByRowIconPrimaryColor(
            timelineOverlayMessage,
            context,
          ),
          size: MessageTimeStyle.seenByRowIconSize,
        );
      case MessageStatus.error:
        return Icon(
          Icons.error,
          color: Theme.of(context).colorScheme.error,
          size: MessageTimeStyle.seenByRowIconSize,
        );
    }
  }
}

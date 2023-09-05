import 'package:fluffychat/pages/chat/events/message_time_style.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

enum MessageStatus {
  sending,
  sent,
  hasBeenSeenByOne,
  hasBeenSeenByAll,
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

    if (seenByUsers.length == participants.length - 1) {
      return MessageStatus.hasBeenSeenByAll;
    }

    return MessageStatus.hasBeenSeenByOne;
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
          Icons.done,
          color: MessageTimeStyle.seenByRowIconSecondaryColor(
            timelineOverlayMessage,
            context,
          ),
          size: MessageTimeStyle.seenByRowIconSize,
        );
      case MessageStatus.hasBeenSeenByAll:
        return Icon(
          Icons.done_all,
          color: MessageTimeStyle.seenByRowIconPrimaryColor(
            timelineOverlayMessage,
            context,
          ),
          size: MessageTimeStyle.seenByRowIconSize,
        );
      case MessageStatus.hasBeenSeenByOne:
        return Icon(
          Icons.done_all,
          color: MessageTimeStyle.seenByRowIconSecondaryColor(
            timelineOverlayMessage,
            context,
          ),
          size: MessageTimeStyle.seenByRowIconSize,
        );
    }
  }
}

import 'package:fluffychat/pages/chat/events/reply_content.dart';
import 'package:fluffychat/pages/chat/events/reply_content_style.dart';
import 'package:fluffychat/pages/chat/optional_ink_well.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class ReplyContentWidget extends StatelessWidget {
  const ReplyContentWidget({
    super.key,
    required this.event,
    required this.timeline,
    required this.scrollToEventId,
    required this.ownMessage,
  });

  final Event event;
  final Timeline timeline;
  final void Function(String p1)? scrollToEventId;
  final bool ownMessage;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Event?>(
      future: event.getReplyEvent(timeline),
      builder: (context, snapshot) {
        Event? replyEvent;
        if (snapshot.data != null) {
          replyEvent = snapshot.data;
        } else if (event.relationshipEventId != null) {
          replyEvent = Event(
            eventId: event.relationshipEventId!,
            content: {'msgtype': 'm.text', 'body': '...'},
            senderId: event.senderId,
            type: 'm.room.message',
            room: event.room,
            status: EventStatus.sent,
            originServerTs: DateTime.now(),
          );
        }

        if (replyEvent == null) return const SizedBox();

        return OptionalInkWell(
          onTap: () => scrollToEventId?.call(replyEvent!.eventId),
          isEnabled: scrollToEventId != null,
          child: Padding(
            padding: ReplyContentStyle.marginReplyContent,
            child: ReplyContent(
              replyEvent,
              ownMessage: ownMessage,
              timeline: timeline,
            ),
          ),
        );
      },
    );
  }
}

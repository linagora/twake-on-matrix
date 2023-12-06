import 'package:fluffychat/pages/chat/events/reply_content.dart';
import 'package:fluffychat/pages/chat/events/reply_content_style.dart';
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
      future: event.getReplyEvent(
        timeline,
      ),
      builder: (
        BuildContext context,
        snapshot,
      ) {
        final replyEvent = snapshot.data ??
            Event(
              eventId: event.relationshipEventId!,
              content: {
                'msgtype': 'm.text',
                'body': '...',
              },
              senderId: event.senderId,
              type: 'm.room.message',
              room: event.room,
              status: EventStatus.sent,
              originServerTs: DateTime.now(),
            );
        return InkWell(
          onTap: () {
            if (scrollToEventId != null) {
              scrollToEventId!(
                replyEvent.eventId,
              );
            }
          },
          child: AbsorbPointer(
            child: Container(
              margin: ReplyContentStyle.marginReplyContent,
              child: ReplyContent(
                replyEvent,
                ownMessage: ownMessage,
                timeline: timeline,
              ),
            ),
          ),
        );
      },
    );
  }
}

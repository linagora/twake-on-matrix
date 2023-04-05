import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/events/message_reactions.dart';
import 'package:fluffychat/pages/chat/seen_by_row.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:matrix/matrix.dart';

class MessageTime extends StatelessWidget {
  const MessageTime({
    Key? key,
    required this.controller,
    required this.event,
    required this.ownMessage,
    required this.timeline,
    required this.timelineOverlayMessage,
  }) : super(key: key);
  final ChatController controller;
  final Event event;
  final bool ownMessage;
  final bool timelineOverlayMessage;
  final Timeline timeline;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: timelineOverlayMessage
          ? const EdgeInsets.symmetric(
              vertical: 6,
              horizontal: 8,
            )
          : null,
      decoration: timelineOverlayMessage
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black.withOpacity(0.4),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (event.hasAggregatedEvents(
            timeline,
            RelationshipTypes.reaction,
          )) ...[
            MessageReactions(event, timeline),
            const SizedBox(width: 4),
          ],
          Text(
            DateFormat("HH:mm").format(event.originServerTs),
            style: TextStyle(
              fontSize: 11 * AppConfig.fontSizeFactor,
              color: timelineOverlayMessage
                  ? Colors.white
                  : ownMessage
                      ? Theme.of(context).colorScheme.secondary
                      : const Color(0xFF818C99),
            ),
          ),
          if (ownMessage) ...[
            const SizedBox(width: 4),
            SeenByRow(
              controller,
              timelineOverlayMessage: timelineOverlayMessage,
              eventId: event.eventId,
              eventStatus: event.status,
            ),
          ],
        ],
      ),
    );
  }
}

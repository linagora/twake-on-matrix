import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/events/message_time_style.dart';
import 'package:fluffychat/pages/chat/seen_by_row.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:matrix/matrix.dart';
import 'package:linagora_design_flutter/colors/linagora_state_layer.dart';
import 'package:fluffychat/utils/room_status_extension.dart';

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
      padding: timelineOverlayMessage
          ? const EdgeInsets.symmetric(
              vertical: 4,
              horizontal: 8,
            )
          : null,
      decoration: timelineOverlayMessage
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: LinagoraStateLayer(Colors.black).opacityLayer3,
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            DateFormat("HH:mm").format(event.originServerTs),
            style: Theme.of(context).textTheme.bodySmall?.merge(
                  TextStyle(
                    color: timelineOverlayMessage
                        ? Colors.white
                        : LinagoraRefColors.material().neutral[50],
                    letterSpacing: 0.4,
                  ),
                ),
          ),
          if (ownMessage) ...[
            SizedBox(width: MessageTimeStyle.paddingTimeAndIcon),
            SeenByRow(
              timelineOverlayMessage: timelineOverlayMessage,
              participants: timeline.room.getParticipants(),
              getSeenByUsers: controller.room!.getSeenByUsers(
                controller.timeline!,
                eventId: event.eventId,
              ),
              eventStatus: event.status,
            ),
          ],
        ],
      ),
    );
  }
}

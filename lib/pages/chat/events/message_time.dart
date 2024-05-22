import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:fluffychat/pages/chat/events/message_time_style.dart';
import 'package:fluffychat/pages/chat/seen_by_row.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:matrix/matrix.dart';
import 'package:linagora_design_flutter/colors/linagora_state_layer.dart';
import 'package:fluffychat/utils/room_status_extension.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class MessageTime extends StatelessWidget {
  const MessageTime({
    super.key,
    required this.event,
    required this.ownMessage,
    required this.timeline,
    required this.timelineOverlayMessage,
    required this.room,
  });

  final Event event;
  final bool ownMessage;
  final bool timelineOverlayMessage;
  final Timeline timeline;
  final Room room;

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
          if (event.isPinned) ...[
            TwakeIconButton(
              tooltip: L10n.of(context)!.pin,
              icon: Icons.push_pin_outlined,
              size: MessageStyle.pushpinIconSize,
              paddingAll: MessageStyle.paddingAllPushpin,
              margin: EdgeInsets.zero,
              iconColor: timelineOverlayMessage
                  ? Colors.white
                  : LinagoraRefColors.material().neutral[50],
            ),
            const SizedBox(width: 4.0),
          ],
          Text(
            DateFormat("HH:mm").format(event.originServerTs),
            textScaler: const TextScaler.linear(1.0),
            style: Theme.of(context).textTheme.bodySmall?.merge(
                  TextStyle(
                    color: timelineOverlayMessage
                        ? Colors.white
                        : LinagoraRefColors.material().tertiary[30],
                    letterSpacing: 0.4,
                  ),
                ),
          ),
          if (ownMessage) ...[
            SizedBox(width: MessageTimeStyle.paddingTimeAndIcon),
            SeenByRow(
              timelineOverlayMessage: timelineOverlayMessage,
              participants: timeline.room.getParticipants(),
              getSeenByUsers: room.getSeenByUsers(
                timeline,
                eventId: event.eventId,
              ),
              eventStatus: event.status,
              event: event,
            ),
          ],
        ],
      ),
    );
  }
}

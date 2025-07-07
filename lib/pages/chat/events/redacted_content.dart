import 'package:fluffychat/pages/chat/events/message_content_mixin.dart';
import 'package:fluffychat/pages/chat/events/message_time.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

class RedactedContent extends StatelessWidget with MessageContentMixin {
  final Event event;
  final Timeline timeline;

  const RedactedContent({
    super.key,
    required this.event,
    required this.timeline,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: 8,
        top: event.isOwnMessage ? 4 : 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              L10n.of(context)!.deletedMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 17,
                    height: 24 / 17,
                    color: LinagoraRefColors.material().tertiary[30],
                  ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 8),
          MessageTime(
            timelineOverlayMessage: event.timelineOverlayMessage,
            room: event.room,
            event: event,
            showSeenIcon: false,
            timeline: timeline,
          ),
        ],
      ),
    );
  }
}

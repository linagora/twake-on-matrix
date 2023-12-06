import 'package:fluffychat/pages/chat/events/message/display_name_widget.dart';
import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:fluffychat/pages/chat/events/message_time.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/pages/chat/events/message/reply_content_widget.dart';
import 'package:fluffychat/pages/chat/events/message_content.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'dart:math';

class MessageContentBuilder extends StatelessWidget {
  final Event event;
  final Timeline timeline;
  final BoxConstraints availableBubbleContraints;
  final void Function(String)? scrollToEventId;
  final void Function(Event)? onSelect;
  final Event? nextEvent;
  final bool selectMode;

  const MessageContentBuilder({
    super.key,
    required this.event,
    required this.timeline,
    required this.availableBubbleContraints,
    this.onSelect,
    this.nextEvent,
    this.scrollToEventId,
    this.selectMode = true,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onBackground;
    final displayEvent = event.getDisplayEvent(timeline);
    final noPadding = {
      MessageTypes.File,
      MessageTypes.Audio,
    }.contains(event.messageType);
    return Padding(
      padding: EdgeInsets.only(
        bottom: noPadding || event.timelineOverlayMessage ? 0 : 8,
      ),
      child: IntrinsicWidth(
        stepWidth: _getSizeMessageBubbleWidth(
          context,
          maxWidth: availableBubbleContraints.maxWidth,
          ownMessage: event.isOwnMessage,
          hideDisplayName: nextEvent != null &&
              event.hideDisplayName(
                nextEvent!,
              ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (event.relationshipType == RelationshipTypes.reply)
              ReplyContentWidget(
                event: event,
                timeline: timeline,
                scrollToEventId: scrollToEventId,
                ownMessage: event.isOwnMessage,
              ),
            Stack(
              children: [
                MessageContent(
                  displayEvent,
                  textColor: textColor,
                  endOfBubbleWidget: Padding(
                    padding: MessageStyle.paddingTimestamp,
                    child: SelectionContainer.disabled(
                      child: MessageTime(
                        timelineOverlayMessage: event.timelineOverlayMessage,
                        event: event,
                        ownMessage: event.isOwnMessage,
                        timeline: timeline,
                        room: event.room,
                      ),
                    ),
                  ),
                  backgroundColor: event.isOwnMessage
                      ? Theme.of(
                          context,
                        ).colorScheme.primaryContainer
                      : Theme.of(
                          context,
                        ).colorScheme.surface,
                  onTapSelectMode: () => selectMode
                      ? onSelect!(
                          event,
                        )
                      : null,
                  onTapPreview: !selectMode ? () {} : null,
                  ownMessage: event.isOwnMessage,
                ),
                if (event.timelineOverlayMessage)
                  Positioned(
                    right: 8,
                    bottom: 4.0,
                    child: SelectionContainer.disabled(
                      child: MessageTime(
                        timelineOverlayMessage: event.timelineOverlayMessage,
                        event: event,
                        ownMessage: event.isOwnMessage,
                        timeline: timeline,
                        room: event.room,
                      ),
                    ),
                  ),
              ],
            ),
            if (event.hasAggregatedEvents(
              timeline,
              RelationshipTypes.edit,
            ))
              Padding(
                padding: MessageStyle.paddingEditButton,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      color: textColor.withAlpha(
                        164,
                      ),
                      size: 14,
                    ),
                    Text(
                      ' - ${displayEvent.originServerTs.localizedTimeShort(context)}',
                      style: TextStyle(
                        color: textColor.withAlpha(
                          164,
                        ),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  double? _getSizeMessageBubbleWidth(
    BuildContext context, {
    required double maxWidth,
    bool ownMessage = false,
    bool hideDisplayName = false,
  }) {
    final isNotSupportCalcSize = {
      MessageTypes.File,
      MessageTypes.Image,
      MessageTypes.Video,
    }.contains(event.messageType);

    if (ownMessage || hideDisplayName || isNotSupportCalcSize) {
      return null;
    }

    final sizeWidthDisplayName = _getSizeDisplayName(
      context,
      maxWidth,
    ).width;

    final sizeWidthMessageText = _getSizeMessageText(
      context,
      maxWidth,
    ).width;

    return max<double>(sizeWidthDisplayName, sizeWidthMessageText);
  }

  TextPainter _getSizeDisplayName(
    BuildContext context,
    double maxWidth,
  ) {
    return TextPainter(
      text: TextSpan(
        text: event.senderFromMemoryOrFallback
            .calcDisplayname()
            .shortenDisplayName(
              maxCharacters: DisplayNameWidget.maxCharactersDisplayNameBubble,
            ),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.primary,
            ),
      ),
      maxLines: 2,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: maxWidth);
  }

  TextPainter _getSizeMessageText(
    BuildContext context,
    double maxWidth,
  ) {
    return TextPainter(
      text: TextSpan(
        text: event.calcLocalizedBodyFallback(
          MatrixLocals(L10n.of(context)!),
          hideReply: true,
        ),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.primary,
            ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: maxWidth);
  }
}

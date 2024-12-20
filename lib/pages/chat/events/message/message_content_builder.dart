import 'package:fluffychat/pages/chat/events/message/message_content_builder_mixin.dart';
import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:fluffychat/pages/chat/events/message_time.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/pages/chat/events/message/reply_content_widget.dart';
import 'package:fluffychat/pages/chat/events/message_content.dart';
import 'package:matrix/matrix.dart' hide Visibility;
import 'message.dart';

class MessageContentBuilder extends StatelessWidget
    with MessageContentBuilderMixin {
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
    // TODO: change to colorSurface when its approved
    // ignore: deprecated_member_use
    final textColor = Theme.of(context).colorScheme.onBackground;
    final displayEvent = event.getDisplayEvent(timeline);
    final noPadding = {
      MessageTypes.File,
      MessageTypes.Audio,
    }.contains(event.messageType);
    final sizeMessageBubble = getSizeMessageBubbleWidth(
      context,
      event: event,
      maxWidth: availableBubbleContraints.maxWidth,
      ownMessage: event.isOwnMessage,
      hideDisplayName: event.hideDisplayName(
        nextEvent,
        Message.responsiveUtils.isMobile(context),
      ),
    );
    final stepWidth = sizeMessageBubble?.totalMessageWidth;
    final isNeedAddNewLine = sizeMessageBubble?.isNeedAddNewLine ?? false;
    return Padding(
      padding: EdgeInsets.only(
        bottom: noPadding || event.timelineOverlayMessage ? 0 : 8,
      ),
      child: IntrinsicWidth(
        stepWidth: isContainsTagName(event) || isContainsSpecialHTMLTag(event)
            ? null
            : stepWidth,
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
                      child: Text.rich(
                        WidgetSpan(
                          child: MessageTime(
                            timelineOverlayMessage:
                                event.timelineOverlayMessage,
                            event: event,
                            ownMessage: event.isOwnMessage,
                            timeline: timeline,
                            room: event.room,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (isNeedAddNewLine ||
                isContainsTagName(event) ||
                isContainsSpecialHTMLTag(event))
              Visibility(
                visible: false,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: SelectionContainer.disabled(
                  child: Text.rich(
                    WidgetSpan(
                      child: MessageTime(
                        timelineOverlayMessage: event.timelineOverlayMessage,
                        event: event,
                        ownMessage: event.isOwnMessage,
                        timeline: timeline,
                        room: event.room,
                      ),
                    ),
                  ),
                ),
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
}

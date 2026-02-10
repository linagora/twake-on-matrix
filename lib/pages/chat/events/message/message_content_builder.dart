import 'package:fluffychat/pages/chat/events/message/message_content_builder_mixin.dart';
import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:fluffychat/pages/chat/events/message_time.dart';
import 'package:fluffychat/pages/chat/optional_padding.dart';
import 'package:fluffychat/pages/chat/optional_selection_container_disabled.dart';
import 'package:fluffychat/pages/chat/optional_stack.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/pages/chat/events/message/reply_content_widget.dart';
import 'package:fluffychat/pages/chat/events/message_content.dart';
import 'package:matrix/matrix.dart' hide Visibility;
import 'message.dart';

class MessageContentBuilder extends StatelessWidget
    with MessageContentBuilderMixin {
  final Event event;
  final Timeline timeline;
  final void Function(String)? scrollToEventId;
  final void Function(Event)? onSelect;
  final Event? nextEvent;
  final bool selectMode;
  final Future<void> Function(Event)? onRetryTextMessage;

  const MessageContentBuilder({
    super.key,
    required this.event,
    required this.timeline,
    this.onSelect,
    this.nextEvent,
    this.scrollToEventId,
    this.selectMode = true,
    this.onRetryTextMessage,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // TODO: change to colorSurface when its approved
        // ignore: deprecated_member_use
        final textColor = Theme.of(context).colorScheme.onBackground;
        final displayEvent = event.getDisplayEventWithoutEditEvent(timeline);
        final noPadding = {
          MessageTypes.File,
          MessageTypes.Audio,
        }.contains(event.messageType);
        final sizeMessageBubble = getSizeMessageBubbleWidth(
          context,
          event: event,
          maxWidth: constraints.maxWidth,
          ownMessage: event.isOwnMessage,
          hideDisplayName: event.hideDisplayName(
            nextEvent,
            Message.responsiveUtils.isMobile(context),
          ),
          isEdited: event.hasAggregatedEvents(timeline, RelationshipTypes.edit),
        );
        final stepWidth = sizeMessageBubble?.totalMessageWidth;
        final isNeedAddNewLine = sizeMessageBubble?.isNeedAddNewLine ?? false;
        final isTextMessageError =
            event.status.isError && event.messageType == MessageTypes.Text;

        return OptionalPadding(
          padding: const EdgeInsets.only(bottom: 8),
          isEnabled: !noPadding && !event.timelineOverlayMessage,
          child: IntrinsicWidth(
            stepWidth:
                isContainsTagName(event) ||
                    isContainsSpecialHTMLTag(event) ||
                    event.isCaptionModeOrReply()
                ? null
                : stepWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (event.inReplyToEventId() != null)
                  ReplyContentWidget(
                    event: event,
                    timeline: timeline,
                    scrollToEventId: scrollToEventId,
                    ownMessage: event.isOwnMessage,
                  ),
                OptionalStack(
                  isEnabled: event.timelineOverlayMessage,
                  children: [
                    MessageContent(
                      displayEvent,
                      textColor: textColor,
                      textWidth: stepWidth,
                      endOfBubbleWidget: Padding(
                        padding: MessageStyle.paddingTimestamp,
                        child: MessageTime(
                          timelineOverlayMessage: event.timelineOverlayMessage,
                          event: event,
                          showSeenIcon: event.isOwnMessage,
                          timeline: timeline,
                          room: event.room,
                          onRetryTextMessage: onRetryTextMessage,
                        ),
                      ),
                      onTapSelectMode: () =>
                          selectMode ? onSelect!(event) : null,
                      onTapPreview: !selectMode ? () {} : null,
                      ownMessage: event.isOwnMessage,
                      timeline: timeline,
                    ),
                    PositionedDirectional(
                      end: 8,
                      bottom: 4.0,
                      child: OptionalSelectionContainerDisabled(
                        isEnabled: PlatformInfos.isWeb,
                        child: Text.rich(
                          WidgetSpan(
                            child: MessageTime(
                              timelineOverlayMessage:
                                  event.timelineOverlayMessage,
                              event: event,
                              showSeenIcon: event.isOwnMessage,
                              timeline: timeline,
                              room: event.room,
                              onRetryTextMessage: onRetryTextMessage,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!event.isReplyEventWithAudio() &&
                    (isNeedAddNewLine ||
                        isTextMessageError ||
                        isContainsTagName(event) ||
                        isContainsSpecialHTMLTag(event)))
                  OptionalSelectionContainerDisabled(
                    isEnabled: PlatformInfos.isWeb,
                    child: Visibility(
                      visible: false,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: Text.rich(
                        WidgetSpan(
                          child: MessageTime(
                            timelineOverlayMessage:
                                event.timelineOverlayMessage,
                            event: event,
                            showSeenIcon: event.isOwnMessage,
                            timeline: timeline,
                            room: event.room,
                            onRetryTextMessage: onRetryTextMessage,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

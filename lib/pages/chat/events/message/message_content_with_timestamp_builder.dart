import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/chat/context_item_chat_action.dart';
import 'package:fluffychat/pages/chat/events/message/display_name_widget.dart';
import 'package:fluffychat/pages/chat/events/message/message.dart';
import 'package:fluffychat/pages/chat/events/message/message_content_builder.dart';
import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:fluffychat/pages/chat/events/message/multi_platform_message_container.dart';
import 'package:fluffychat/pages/chat/events/message_reactions.dart';
import 'package:fluffychat/pages/chat/events/message_time.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class MessageContentWithTimestampBuilder extends StatelessWidget {
  final Event event;
  final Event? nextEvent;
  final void Function(Event)? onSelect;
  final void Function(String)? scrollToEventId;
  final ValueNotifier<String?> isHoverNotifier;
  final bool longPressSelect;
  final bool selected;
  final Timeline timeline;
  final List<ContextMenuItemChatAction> listHorizontalActionMenu;
  final OnMenuAction? onMenuAction;
  final bool selectMode;

  static final responsiveUtils = getIt.get<ResponsiveUtils>();

  const MessageContentWithTimestampBuilder({
    super.key,
    required this.event,
    this.nextEvent,
    this.longPressSelect = false,
    this.onSelect,
    this.scrollToEventId,
    this.selected = false,
    this.selectMode = true,
    required this.timeline,
    required this.isHoverNotifier,
    required this.listHorizontalActionMenu,
    this.onMenuAction,
  });

  @override
  Widget build(BuildContext context) {
    final displayTime = event.type == EventTypes.RoomCreate ||
        nextEvent == null ||
        !event.originServerTs.sameEnvironment(nextEvent!.originServerTs);
    final noBubble = {
          MessageTypes.Sticker,
        }.contains(event.messageType) &&
        !event.redacted;

    final timelineText = {
      MessageTypes.Text,
      MessageTypes.BadEncrypted,
    }.contains(event.messageType);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment:
          event.isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (event.isOwnMessage)
          _menuActionsRowBuilder(context, event.isOwnMessage),
        Container(
          alignment:
              event.isOwnMessage ? Alignment.topRight : Alignment.topLeft,
          padding: MessageStyle.paddingMessageContainer(
            displayTime,
            context,
            nextEvent,
            event,
            selected,
          ),
          child: MultiPlatformSelectionMode(
            event: event,
            longPressSelect: longPressSelect,
            useInkWell: !PlatformInfos.isWeb,
            onSelect: onSelect,
            child: Stack(
              alignment: event.isOwnMessage
                  ? AlignmentDirectional.bottomStart
                  : AlignmentDirectional.bottomEnd,
              children: [
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: MessageStyle.bubbleBorderRadius,
                        color: event.isOwnMessage
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surface,
                      ),
                      padding: noBubble
                          ? const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            )
                          : MessageStyle.paddingMessageContentBuilder(event),
                      constraints: BoxConstraints(
                        maxWidth: MessageStyle.messageBubbleWidth(
                          context,
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (
                          context,
                          availableBubbleContraints,
                        ) =>
                            Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            nextEvent != null &&
                                        event.hideDisplayName(nextEvent!) ||
                                    event.hideDisplayNameInBubbleChat
                                ? const SizedBox()
                                : DisplayNameWidget(
                                    event: event,
                                  ),
                            IntrinsicHeight(
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  MessageContentBuilder(
                                    event: event,
                                    timeline: timeline,
                                    availableBubbleContraints:
                                        availableBubbleContraints,
                                    onSelect: onSelect,
                                    nextEvent: nextEvent,
                                    scrollToEventId: scrollToEventId,
                                    selectMode: selectMode,
                                  ),
                                  if (timelineText)
                                    Positioned(
                                      child: SelectionContainer.disabled(
                                        child: Padding(
                                          padding:
                                              MessageStyle.paddingMessageTime,
                                          child: MultiPlatformSelectionMode(
                                            useInkWell: PlatformInfos.isWeb,
                                            longPressSelect: longPressSelect,
                                            onSelect: onSelect,
                                            event: event,
                                            child: MessageTime(
                                              timelineOverlayMessage:
                                                  event.timelineOverlayMessage,
                                              room: event.room,
                                              event: event,
                                              ownMessage: event.isOwnMessage,
                                              timeline: timeline,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (event.hasAggregatedEvents(
                      timeline,
                      RelationshipTypes.reaction,
                    ))
                      const SizedBox(height: 24),
                  ],
                ),
                if (event.hasAggregatedEvents(
                  timeline,
                  RelationshipTypes.reaction,
                )) ...[
                  Positioned(
                    left: 8,
                    right: 0,
                    bottom: 0,
                    child: MessageReactions(event, timeline),
                  ),
                  const SizedBox(width: 4),
                ],
              ],
            ),
          ),
        ),
        if (!event.isOwnMessage)
          _menuActionsRowBuilder(context, event.isOwnMessage),
      ],
    );
  }

  Widget _menuActionsRowBuilder(BuildContext context, bool ownMessage) {
    return ValueListenableBuilder(
      valueListenable: isHoverNotifier,
      builder: (context, isHover, child) {
        if (isHover != null && isHover.contains(event.eventId) && !selected) {
          return child!;
        }
        return const SizedBox();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: listHorizontalActionMenu.map((item) {
            return Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
              child: TwakeIconButton(
                icon: item.action.getIcon(),
                imagePath: item.action.getImagePath(),
                tooltip: item.action.getTitle(context),
                preferBelow: false,
                onTapDown: (context) => onMenuAction!(
                  context,
                  item.action,
                  event,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

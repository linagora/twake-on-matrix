import 'dart:math' as math;

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/chat_horizontal_action_menu.dart';
import 'package:fluffychat/pages/chat/context_item_chat_action.dart';
import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:fluffychat/pages/chat/events/message_content.dart';
import 'package:fluffychat/pages/chat/events/message_reactions.dart';
import 'package:fluffychat/pages/chat/events/message_time.dart';
import 'package:fluffychat/pages/chat/events/reply_content.dart';
import 'package:fluffychat/pages/chat/events/state_message.dart';
import 'package:fluffychat/pages/chat/events/verification_request_content.dart';
import 'package:fluffychat/pages/chat/sticky_timstamp_widget.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/swipeable.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

typedef OnMenuAction = Function(BuildContext, ChatHorizontalActionMenu, Event);

class Message extends StatelessWidget {
  final Event event;
  final Event? previousEvent;
  final Event? nextEvent;
  final void Function(Event)? onSelect;
  final void Function(Event)? onAvatarTab;
  final void Function(String)? scrollToEventId;
  final void Function(SwipeDirection) onSwipe;
  final void Function(bool, Event)? onHover;
  final ValueNotifier<String?> isHover;
  final bool longPressSelect;
  final bool selected;
  final Timeline timeline;
  final ChatController controller;
  final List<ContextMenuItemChatAction> listHorizontalActionMenu;
  final OnMenuAction? onMenuAction;

  const Message(
    this.event, {
    this.previousEvent,
    this.nextEvent,
    this.longPressSelect = false,
    this.onSelect,
    this.onAvatarTab,
    this.onHover,
    this.scrollToEventId,
    required this.onSwipe,
    this.selected = false,
    required this.timeline,
    required this.controller,
    required this.isHover,
    required this.listHorizontalActionMenu,
    Key? key,
    this.onMenuAction,
  }) : super(key: key);

  /// Indicates wheither the user may use a mouse instead
  /// of touchscreen.
  static bool useMouse = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      hoverColor: Colors.transparent,
      onTap: () => controller.hideKeyboardChatScreen(),
      onHover: (hover) {
        onHover!(hover, event);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (!{
            EventTypes.Message,
            EventTypes.Sticker,
            EventTypes.Encrypted,
            EventTypes.CallInvite,
          }.contains(event.type)) {
            if (event.type.startsWith('m.call.')) {
              return Container();
            }
            return StateMessage(event);
          }

          if (event.type == EventTypes.Message &&
              event.messageType == EventTypes.KeyVerificationRequest) {
            return VerificationRequestContent(event: event, timeline: timeline);
          }

          final client = Matrix.of(context).client;
          final ownMessage = event.senderId == client.userID;
          final alignment = ownMessage ? Alignment.topRight : Alignment.topLeft;
          final displayTime = event.type == EventTypes.RoomCreate ||
              nextEvent == null ||
              !event.originServerTs.sameEnvironment(nextEvent!.originServerTs);
          final textColor = Theme.of(context).colorScheme.onBackground;
          final rowMainAxisAlignment =
              ownMessage ? MainAxisAlignment.end : MainAxisAlignment.start;

          final displayEvent = event.getDisplayEvent(timeline);
          final noBubble = {
                MessageTypes.Sticker,
              }.contains(event.messageType) &&
              !event.redacted;
          final timelineOverlayMessage = {
            MessageTypes.Video,
            MessageTypes.Image,
          }.contains(event.messageType);
          final timelineText = {
            MessageTypes.Text,
            MessageTypes.BadEncrypted,
          }.contains(event.messageType);
          final noPadding = {
            MessageTypes.File,
            MessageTypes.Audio,
          }.contains(event.messageType);

          final rowChildren = <Widget>[
            _placeHolderWidget(
              isSameSender(previousEvent, event),
              ownMessage,
              event,
            ),
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: ownMessage
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (ownMessage) _menuActionsRowBuilder(context, ownMessage),
                  Container(
                    alignment: alignment,
                    padding: EdgeInsetsDirectional.only(
                      top: MessageStyle.messageSpacing(
                        displayTime,
                        nextEvent,
                        event,
                      ),
                      start: 8,
                      end: selected || controller.responsive.isDesktop(context)
                          ? 8
                          : 0,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: MessageStyle.bubbleBorderRadius,
                      borderOnForeground: false,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        onEnter: (event) {
                          useMouse = true;
                        },
                        onExit: (event) {
                          useMouse = false;
                        },
                        child: InkWell(
                          onTap: () =>
                              !longPressSelect ? onSelect!(event) : null,
                          onLongPress: () => longPressSelect && !useMouse
                              ? onSelect!(event)
                              : null,
                          borderRadius: MessageStyle.bubbleBorderRadius,
                          hoverColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          child: Stack(
                            alignment: ownMessage
                                ? AlignmentDirectional.bottomStart
                                : AlignmentDirectional.bottomEnd,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          MessageStyle.bubbleBorderRadius,
                                      color: ownMessage
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primaryContainer
                                          : Theme.of(context)
                                              .colorScheme
                                              .surface,
                                    ),
                                    padding: noBubble
                                        ? const EdgeInsets.symmetric(
                                            horizontal: 16.0,
                                          )
                                        : EdgeInsets.only(
                                            left:
                                                8 * AppConfig.bubbleSizeFactor,
                                            right:
                                                8 * AppConfig.bubbleSizeFactor,
                                            top: 8 * AppConfig.bubbleSizeFactor,
                                            bottom: timelineOverlayMessage
                                                ? 8 * AppConfig.bubbleSizeFactor
                                                : 0 *
                                                    AppConfig.bubbleSizeFactor,
                                          ),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          hideDisplayName(ownMessage)
                                              ? const SizedBox(height: 0)
                                              : FutureBuilder<User?>(
                                                  future:
                                                      event.fetchSenderUser(),
                                                  builder: (context, snapshot) {
                                                    final displayName = snapshot
                                                            .data
                                                            ?.calcDisplayname() ??
                                                        event
                                                            .senderFromMemoryOrFallback
                                                            .calcDisplayname();
                                                    return Padding(
                                                      padding: EdgeInsets.only(
                                                        left:
                                                            event.messageType ==
                                                                    MessageTypes
                                                                        .Image
                                                                ? 0
                                                                : 8.0,
                                                        bottom: 4.0,
                                                      ),
                                                      child: Text(
                                                        displayName,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .labelMedium
                                                            ?.copyWith(
                                                              color: Theme.of(
                                                                context,
                                                              )
                                                                  .colorScheme
                                                                  .primary,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                          IntrinsicHeight(
                                            child: Stack(
                                              alignment: Alignment.bottomRight,
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                    bottom: noPadding ||
                                                            timelineOverlayMessage
                                                        ? 0
                                                        : 8,
                                                  ),
                                                  child: IntrinsicWidth(
                                                    child: SelectionArea(
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: <Widget>[
                                                          if (event
                                                                  .relationshipType ==
                                                              RelationshipTypes
                                                                  .reply)
                                                            FutureBuilder<
                                                                Event?>(
                                                              future: event
                                                                  .getReplyEvent(
                                                                timeline,
                                                              ),
                                                              builder: (
                                                                BuildContext
                                                                    context,
                                                                snapshot,
                                                              ) {
                                                                final replyEvent =
                                                                    snapshot
                                                                            .hasData
                                                                        ? snapshot
                                                                            .data!
                                                                        : Event(
                                                                            eventId:
                                                                                event.relationshipEventId!,
                                                                            content: {
                                                                              'msgtype': 'm.text',
                                                                              'body': '...',
                                                                            },
                                                                            senderId:
                                                                                event.senderId,
                                                                            type:
                                                                                'm.room.message',
                                                                            room:
                                                                                event.room,
                                                                            status:
                                                                                EventStatus.sent,
                                                                            originServerTs:
                                                                                DateTime.now(),
                                                                          );
                                                                return InkWell(
                                                                  onTap: () {
                                                                    if (scrollToEventId !=
                                                                        null) {
                                                                      scrollToEventId!(
                                                                        replyEvent
                                                                            .eventId,
                                                                      );
                                                                    }
                                                                  },
                                                                  child:
                                                                      AbsorbPointer(
                                                                    child:
                                                                        Container(
                                                                      margin: EdgeInsets
                                                                          .symmetric(
                                                                        vertical:
                                                                            4.0 *
                                                                                AppConfig.bubbleSizeFactor,
                                                                      ),
                                                                      child:
                                                                          ReplyContent(
                                                                        replyEvent,
                                                                        ownMessage:
                                                                            ownMessage,
                                                                        timeline:
                                                                            timeline,
                                                                        chatController:
                                                                            controller,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          Stack(
                                                            children: [
                                                              MessageContent(
                                                                displayEvent,
                                                                textColor:
                                                                    textColor,
                                                                endOfBubbleWidget:
                                                                    Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                    left: 8.0,
                                                                    right: 4.0,
                                                                  ),
                                                                  child:
                                                                      MessageTime(
                                                                    timelineOverlayMessage:
                                                                        timelineOverlayMessage,
                                                                    controller:
                                                                        controller,
                                                                    event:
                                                                        event,
                                                                    ownMessage:
                                                                        ownMessage,
                                                                    timeline:
                                                                        timeline,
                                                                  ),
                                                                ),
                                                                controller:
                                                                    controller,
                                                                backgroundColor:
                                                                    ownMessage
                                                                        ? Theme
                                                                                .of(
                                                                            context,
                                                                          )
                                                                            .colorScheme
                                                                            .primaryContainer
                                                                        : Theme
                                                                            .of(
                                                                            context,
                                                                          ).colorScheme.surface,
                                                                onTapSelectMode:
                                                                    () => controller
                                                                            .selectMode
                                                                        ? onSelect!(
                                                                            event,
                                                                          )
                                                                        : null,
                                                                onTapPreview:
                                                                    !controller
                                                                            .selectMode
                                                                        ? () {}
                                                                        : null,
                                                                ownMessage:
                                                                    ownMessage,
                                                              ),
                                                              if (timelineOverlayMessage)
                                                                Positioned(
                                                                  right: 8,
                                                                  bottom: 4.0,
                                                                  child:
                                                                      MessageTime(
                                                                    timelineOverlayMessage:
                                                                        timelineOverlayMessage,
                                                                    controller:
                                                                        controller,
                                                                    event:
                                                                        event,
                                                                    ownMessage:
                                                                        ownMessage,
                                                                    timeline:
                                                                        timeline,
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                          if (event
                                                              .hasAggregatedEvents(
                                                            timeline,
                                                            RelationshipTypes
                                                                .edit,
                                                          ))
                                                            Padding(
                                                              padding:
                                                                  EdgeInsets
                                                                      .only(
                                                                top: 4.0 *
                                                                    AppConfig
                                                                        .bubbleSizeFactor,
                                                              ),
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .edit_outlined,
                                                                    color: textColor
                                                                        .withAlpha(
                                                                      164,
                                                                    ),
                                                                    size: 14,
                                                                  ),
                                                                  Text(
                                                                    ' - ${displayEvent.originServerTs.localizedTimeShort(context)}',
                                                                    style:
                                                                        TextStyle(
                                                                      color: textColor
                                                                          .withAlpha(
                                                                        164,
                                                                      ),
                                                                      fontSize:
                                                                          12,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                if (timelineText)
                                                  Positioned(
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                        left: 6,
                                                        right: 8.0,
                                                        bottom: 4.0,
                                                      ),
                                                      child: MessageTime(
                                                        timelineOverlayMessage:
                                                            timelineOverlayMessage,
                                                        controller: controller,
                                                        event: event,
                                                        ownMessage: ownMessage,
                                                        timeline: timeline,
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
                    ),
                  ),
                  if (!ownMessage) _menuActionsRowBuilder(context, ownMessage),
                ],
              ),
            ),
          ];
          final row = Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: rowMainAxisAlignment,
            children: rowChildren,
          );

          return Column(
            children: [
              if (displayTime)
                StickyTimestampWidget(
                  content: event.originServerTs.relativeTime(context),
                ),
              Swipeable(
                key: ValueKey(event.eventId),
                background: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Center(
                    child: Icon(Icons.reply_outlined),
                  ),
                ),
                onOverScrollTheMaxOffset: () => HapticFeedback.heavyImpact(),
                maxOffset: 0.4,
                movementDuration: const Duration(milliseconds: 100),
                swipeIntensity: 2.5,
                direction: SwipeDirection.endToStart,
                onSwipe: onSwipe,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: ownMessage
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onLongPress: () =>
                          controller.selectMode ? onSelect!(event) : null,
                      onTap: () => controller.selectMode
                          ? onSelect!(event)
                          : controller.hideKeyboardChatScreen(),
                      child: Center(
                        child: Container(
                          margin: EdgeInsetsDirectional.only(
                            start: selected ? 0.0 : 8.0,
                          ),
                          padding: EdgeInsets.only(
                            right: selected
                                ? 0
                                : ownMessage ||
                                        controller.responsive.isDesktop(context)
                                    ? 8.0
                                    : 16.0,
                            top: selected ? 0 : 1.0,
                            bottom: selected ? 0 : 1.0,
                          ),
                          child: _messageSelectedWidget(context, row),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool hideDisplayName(bool ownMessage) =>
      ownMessage ||
      event.room.isDirectChat ||
      !isSameSender(nextEvent, event) ||
      event.type == EventTypes.Encrypted;

  Widget _menuActionsRowBuilder(BuildContext context, bool ownMessage) {
    return ValueListenableBuilder(
      valueListenable: isHover,
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

  Widget _placeHolderWidget(bool sameSender, bool ownMessage, Event event) {
    if (controller.selectMode || event.room.isDirectChat) {
      return const SizedBox();
    }

    if (sameSender && !ownMessage) {
      return FutureBuilder<User?>(
        future: event.fetchSenderUser(),
        builder: (context, snapshot) {
          final user = snapshot.data ?? event.senderFromMemoryOrFallback;
          return Avatar(
            size: MessageStyle.avatarSize,
            fontSize: MessageStyle.fontSize,
            mxContent: user.avatarUrl,
            name: user.calcDisplayname(),
            onTap: () => onAvatarTab!(event),
          );
        },
      );
    }

    return const SizedBox(width: MessageStyle.avatarSize);
  }

  Widget _messageSelectedWidget(BuildContext context, Widget child) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: selected ? 1 : 0,
      ),
      color: selected
          ? LinagoraSysColors.material().secondaryContainer
          : Theme.of(context).primaryColor.withAlpha(0),
      constraints:
          const BoxConstraints(maxWidth: TwakeThemes.columnWidth * 2.5),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          if (controller.selectMode)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: (selected || controller.responsive.isDesktop(context))
                      ? 16
                      : 8,
                ),
                child: Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected
                      ? LinagoraSysColors.material().primary
                      : Colors.black,
                  size: 20,
                ),
              ),
            ),
          Expanded(
            flex: 9,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  // Check if the sender of the current event is the same as the compared event.
  bool isSameSender(Event? comparedEvent, Event currentEvent) {
    // If the compared event is null, it is assumed that the message is the newest.
    if (comparedEvent == null) {
      return true;
    }

    final isPreviousOrNextEventMessage = {
      EventTypes.Message,
      EventTypes.Sticker,
      EventTypes.Encrypted,
      EventTypes.Redaction,
    }.contains(comparedEvent.type);

    // Ignoring events that are not messages, stickers, encrypted or redaction.
    if (!isPreviousOrNextEventMessage) {
      return true;
    }

    return currentEvent.senderId != comparedEvent.senderId;
  }
}

class ReplyIconWidget extends StatelessWidget {
  final bool isOwnMessage;

  const ReplyIconWidget({
    Key? key,
    required this.isOwnMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: MessageStyle.replyIconFlexMobile,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment:
            isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (isOwnMessage)
            const SizedBox(
              width: 8.0,
            ),
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(math.pi),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MessageStyle.forwardColorBackground(context),
              ),
              width: MessageStyle.forwardContainerSize,
              height: MessageStyle.forwardContainerSize,
              child: const Icon(Icons.reply),
            ),
          ),
          if (!isOwnMessage)
            const SizedBox(
              width: 12.0,
            ),
        ],
      ),
    );
  }
}

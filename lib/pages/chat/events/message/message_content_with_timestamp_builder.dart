import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/chat/events/message/display_name_widget.dart';
import 'package:fluffychat/pages/chat/events/message/message.dart';
import 'package:fluffychat/pages/chat/events/message/message_content_builder.dart';
import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:fluffychat/pages/chat/events/message/multi_platform_message_container.dart';
import 'package:fluffychat/pages/chat/events/message_reactions.dart';
import 'package:fluffychat/pages/chat/events/message_time.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/utils/extension/event_status_custom_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/context_menu/context_menu_action.dart';
import 'package:fluffychat/widgets/context_menu/context_menu_action_item.dart';
import 'package:fluffychat/widgets/context_menu/twake_context_menu_area.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

typedef ContextMenuBuilder = List<Widget> Function(BuildContext context);

class MessageContentWithTimestampBuilder extends StatelessWidget {
  final Event event;
  final Event? nextEvent;
  final void Function(Event)? onSelect;
  final void Function(String)? scrollToEventId;
  final void Function(Event)? onLongPress;
  final ValueNotifier<String?> isHoverNotifier;
  final bool selected;
  final Timeline timeline;
  final List<ContextMenuItemAction> listHorizontalActionMenu;
  final OnMenuAction? onMenuAction;
  final bool selectMode;
  final ContextMenuBuilder? menuChildren;
  final FocusNode? focusNode;
  final List<ContextMenuAction> listActions;

  static final responsiveUtils = getIt.get<ResponsiveUtils>();

  const MessageContentWithTimestampBuilder({
    super.key,
    required this.event,
    this.nextEvent,
    this.onSelect,
    this.scrollToEventId,
    this.onLongPress,
    this.selected = false,
    this.selectMode = true,
    required this.timeline,
    required this.isHoverNotifier,
    required this.listHorizontalActionMenu,
    this.onMenuAction,
    this.menuChildren,
    this.focusNode,
    required this.listActions,
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
      mainAxisAlignment: MessageStyle.messageAlignment(event, context),
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TwakeContextMenuArea(
          builder: menuChildren != null
              ? (context) => menuChildren!.call(context)
              : null,
          listActions: listActions,
          child: Container(
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
              isClickable: responsiveUtils.isMobileOrTablet(context),
              onLongPress: event.status.isAvailable ? onLongPress : null,
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
                              ? LinagoraRefColors.material().primary[95]
                              : responsiveUtils.isMobile(context)
                                  ? LinagoraSysColors.material().onPrimary
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                          border: !event.isOwnMessage &&
                                  responsiveUtils.isMobile(context)
                              ? Border.all(
                                  color: MessageStyle.borderColorReceivedBubble,
                                )
                              : null,
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
                              event.hideDisplayName(
                                nextEvent,
                                responsiveUtils.isMobile(context),
                              )
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
                                            child: Text.rich(
                                              WidgetSpan(
                                                child: MessageTime(
                                                  timelineOverlayMessage: event
                                                      .timelineOverlayMessage,
                                                  room: event.room,
                                                  event: event,
                                                  ownMessage:
                                                      event.isOwnMessage,
                                                  timeline: timeline,
                                                ),
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
        ),
        if (event.status.isAvailable) _menuActionsRowBuilder(context),
      ],
    );
  }

  Widget _menuActionsRowBuilder(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isHoverNotifier,
      builder: (context, isHover, child) {
        if (isHover != null && isHover.contains(event.eventId)) {
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
                onTapDown: (tapDownDetails) => onMenuAction?.call(
                  context,
                  item.action,
                  event,
                  tapDownDetails,
                ),
                icon: item.action.getIcon(),
                imagePath: item.action.getImagePath(),
                tooltip: item.action.getTitle(context),
                preferBelow: false,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/chat/events/message/display_name_widget.dart';
import 'package:fluffychat/pages/chat/events/message/message.dart';
import 'package:fluffychat/pages/chat/events/message/message_content_builder.dart';
import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:fluffychat/pages/chat/events/message/multi_platform_message_container.dart';
import 'package:fluffychat/pages/chat/events/message_reactions.dart';
import 'package:fluffychat/pages/chat/events/message_time.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/utils/extension/event_status_custom_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/context_menu/context_menu_action.dart';
import 'package:fluffychat/widgets/context_menu/context_menu_action_item.dart';
import 'package:fluffychat/widgets/context_menu/twake_context_menu_area.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

typedef ContextMenuBuilder = List<Widget> Function(BuildContext context);

class MessageContentWithTimestampBuilder extends StatelessWidget {
  final Event event;
  final Event? nextEvent;
  final void Function(Event)? onSelect;
  final void Function(String)? scrollToEventId;
  final void Function()? onDisplayEmojiReaction;
  final void Function()? onHideEmojiReaction;
  final ValueNotifier<String?> isHoverNotifier;
  final bool selected;
  final Timeline timeline;
  final List<ContextMenuItemAction> listHorizontalActionMenu;
  final OnMenuAction? onMenuAction;
  final bool selectMode;
  final ContextMenuBuilder? menuChildren;
  final FocusNode? focusNode;
  final List<ContextMenuAction> listActions;
  final OnSendEmojiReactionAction? onSendEmojiReaction;
  final OnPickEmojiReactionAction? onPickEmojiReaction;
  final void Function(Event)? onLongPressMessage;
  final void Function(Event)? onReply;
  final void Function(Event)? onForward;
  final void Function(Event)? onCopy;
  final void Function(Event)? onPin;

  static final responsiveUtils = getIt.get<ResponsiveUtils>();

  const MessageContentWithTimestampBuilder({
    super.key,
    required this.event,
    this.nextEvent,
    this.onSelect,
    this.scrollToEventId,
    this.onDisplayEmojiReaction,
    this.onHideEmojiReaction,
    this.selected = false,
    this.selectMode = true,
    required this.timeline,
    required this.isHoverNotifier,
    required this.listHorizontalActionMenu,
    this.onMenuAction,
    this.menuChildren,
    this.focusNode,
    required this.listActions,
    this.onSendEmojiReaction,
    this.onPickEmojiReaction,
    this.onReply,
    this.onForward,
    this.onCopy,
    this.onLongPressMessage,
    this.onPin,
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
              onLongPress: event.status.isAvailable
                  ? (event) async {
                      if (onLongPressMessage != null) {
                        onLongPressMessage?.call(event);
                        return;
                      }
                      onDisplayEmojiReaction?.call();
                      await Navigator.of(context).push(
                        HeroDialogRoute(
                          builder: (context) {
                            final myReaction = event
                                .aggregatedEvents(
                                  timeline,
                                  RelationshipTypes.reaction,
                                )
                                .where(
                                  (event) =>
                                      event.senderId ==
                                          event.room.client.userID &&
                                      event.type == 'm.reaction',
                                )
                                .firstOrNull;
                            final relatesTo = (myReaction?.content
                                as Map<String, dynamic>?)?['m.relates_to'];
                            return SafeArea(
                              child: ReactionsDialogWidget(
                                id: event.eventId,
                                messageWidget: Material(
                                  color: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        MessageStyle.bubbleBorderRadius,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          MessageStyle.bubbleBorderRadius,
                                    ),
                                    child: SingleChildScrollView(
                                      primary: true,
                                      physics: const ClampingScrollPhysics(),
                                      child: _messageBuilder(
                                        key: ValueKey(
                                          'PreviewReactionWidgetKey%${DateTime.now().millisecondsSinceEpoch}',
                                        ),
                                        mainAxisSize: MainAxisSize.min,
                                        context: context,
                                        timelineText: timelineText,
                                        noBubble: noBubble,
                                        displayTime: displayTime,
                                      ),
                                    ),
                                  ),
                                ),
                                isOwnMessage: event.isOwnMessage,
                                enableMoreEmojiWidget: false,
                                myEmojiReacted: relatesTo?['key'] ?? '',
                                onClickEmojiReactionAction: (emoji) async {
                                  final isSelected =
                                      emoji == (relatesTo?['key'] ?? '');
                                  if (myReaction == null) {
                                    onSendEmojiReaction?.call(emoji, event);
                                    return;
                                  }

                                  if (isSelected) {
                                    Navigator.of(context).pop();
                                    await myReaction.redactEvent();
                                    return;
                                  }

                                  if (!isSelected) {
                                    await myReaction.redactEvent();
                                    onSendEmojiReaction?.call(emoji, event);
                                    return;
                                  }
                                },
                                contextMenuWidget: Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: PullDownMenu(
                                    items: [
                                      PullDownMenuItem(
                                        title: L10n.of(context)!.reply,
                                        onTap: () {
                                          Navigator.of(context).pop('reply');
                                        },
                                        icon: CupertinoIcons
                                            .arrowshape_turn_up_left,
                                      ),
                                      PullDownMenuItem(
                                        title: L10n.of(context)!.forward,
                                        onTap: () {
                                          Navigator.of(context).pop('forward');
                                        },
                                        icon: CupertinoIcons
                                            .arrowshape_turn_up_right,
                                      ),
                                      PullDownMenuItem(
                                        title: L10n.of(context)!.copy,
                                        onTap: () {
                                          Navigator.of(context).pop('copy');
                                        },
                                        icon: CupertinoIcons.doc_on_doc,
                                      ),
                                      PullDownMenuItem(
                                        title: L10n.of(context)!.select,
                                        icon:
                                            CupertinoIcons.checkmark_alt_circle,
                                        onTap: () {
                                          Navigator.of(context).pop('select');
                                        },
                                      ),
                                      PullDownMenuItem(
                                        title: event.isPinned
                                            ? L10n.of(context)!.unpin
                                            : L10n.of(context)!.pin,
                                        icon: event.isPinned
                                            ? null
                                            : Icons.push_pin_outlined,
                                        iconWidget: event.isPinned
                                            ? SvgPicture.asset(
                                                ImagePaths.icUnpin,
                                                colorFilter: ColorFilter.mode(
                                                  LinagoraSysColors.material()
                                                      .onBackground,
                                                  BlendMode.srcIn,
                                                ),
                                              )
                                            : null,
                                        onTap: () {
                                          Navigator.of(context).pop('pin');
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                widgetAlignment: event.isOwnMessage
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                              ),
                            );
                          },
                        ),
                      ).then((result) {
                        _handleResultFromHeroPage(result);
                        onHideEmojiReaction?.call();
                      });
                    }
                  : null,
              child: _messageBuilder(
                key: ValueKey(
                  'MessageContentWithTimestampBuilder%${DateTime.now().millisecondsSinceEpoch}',
                ),
                context: context,
                timelineText: timelineText,
                noBubble: noBubble,
                displayTime: displayTime,
              ),
            ),
          ),
        ),
        if (event.status.isAvailable) _menuActionsRowBuilder(context),
      ],
    );
  }

  void _handleResultFromHeroPage(
    dynamic result,
  ) {
    if (result is String) {
      switch (result) {
        case 'reply':
          onReply?.call(event);
          break;
        case 'forward':
          onForward?.call(event);
          break;
        case 'copy':
          onCopy?.call(event);
          break;
        case 'select':
          onSelect?.call(event);
          break;
        case 'pin':
          onPin?.call(event);
          break;
      }
    }
    onHideEmojiReaction?.call();
  }

  Widget _messageBuilder({
    Key? key,
    required BuildContext context,
    required bool timelineText,
    required bool noBubble,
    required bool displayTime,
    MainAxisSize mainAxisSize = MainAxisSize.max,
  }) {
    return Stack(
      key: key,
      alignment: event.isOwnMessage
          ? AlignmentDirectional.bottomStart
          : AlignmentDirectional.bottomEnd,
      children: [
        Column(
          mainAxisSize: mainAxisSize,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: MessageStyle.bubbleBorderRadius,
                color: event.isOwnMessage
                    ? LinagoraRefColors.material().primary[95]
                    : responsiveUtils.isMobile(context)
                        ? LinagoraSysColors.material().onPrimary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                border: !event.isOwnMessage && responsiveUtils.isMobile(context)
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
                                  padding: MessageStyle.paddingMessageTime,
                                  child: Text.rich(
                                    WidgetSpan(
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

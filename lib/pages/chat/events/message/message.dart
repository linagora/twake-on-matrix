import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/chat/chat_horizontal_action_menu.dart';
import 'package:fluffychat/pages/chat/context_item_chat_action.dart';
import 'package:fluffychat/pages/chat/events/message/message_content_with_timestamp_builder.dart';
import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:fluffychat/pages/chat/events/message/multi_platform_message_container.dart';
import 'package:fluffychat/pages/chat/events/message/swipeable_message.dart';
import 'package:fluffychat/pages/chat/events/state_message.dart';
import 'package:fluffychat/pages/chat/events/verification_request_content.dart';
import 'package:fluffychat/pages/chat/sticky_timstamp_widget.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/swipeable.dart';
import 'package:flutter/material.dart';
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
  final void Function(SwipeDirection)? onSwipe;
  final void Function(bool, Event)? onHover;
  final ValueNotifier<String?> isHoverNotifier;
  final bool longPressSelect;
  final bool selected;
  final Timeline timeline;
  final List<ContextMenuItemChatAction> listHorizontalActionMenu;
  final OnMenuAction? onMenuAction;
  final bool selectMode;
  final VoidCallback? hideKeyboardChatScreen;

  const Message(
    this.event, {
    this.previousEvent,
    this.nextEvent,
    this.longPressSelect = false,
    this.onSelect,
    this.onAvatarTab,
    this.onHover,
    this.scrollToEventId,
    this.onSwipe,
    this.selected = false,
    this.hideKeyboardChatScreen,
    this.selectMode = true,
    required this.timeline,
    required this.isHoverNotifier,
    required this.listHorizontalActionMenu,
    Key? key,
    this.onMenuAction,
  }) : super(key: key);

  /// Indicates wheither the user may use a mouse instead
  /// of touchscreen.
  static bool useMouse = false;

  static final responsiveUtils = getIt.get<ResponsiveUtils>();

  @override
  Widget build(BuildContext context) {
    return MultiPlatformsMessageContainer(
      onTap: hideKeyboardChatScreen,
      onHover: (hover) {
        if (onHover != null) {
          onHover!(hover, event);
        }
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
          final displayTime = event.type == EventTypes.RoomCreate ||
              nextEvent == null ||
              !event.originServerTs.sameEnvironment(nextEvent!.originServerTs);
          final rowMainAxisAlignment =
              ownMessage ? MainAxisAlignment.end : MainAxisAlignment.start;

          final rowChildren = <Widget>[
            _placeHolderWidget(
              event.isSameSenderWith(previousEvent),
              ownMessage,
              event,
            ),
            Expanded(
              child: MessageContentWithTimestampBuilder(
                event: event,
                nextEvent: nextEvent,
                longPressSelect: longPressSelect,
                onSelect: onSelect,
                scrollToEventId: scrollToEventId,
                selected: selected,
                selectMode: selectMode,
                timeline: timeline,
                isHoverNotifier: isHoverNotifier,
                listHorizontalActionMenu: listHorizontalActionMenu,
                onMenuAction: onMenuAction,
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
              SwipeableMessage(
                event: event,
                onSwipe: onSwipe,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: ownMessage
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onLongPress: () => selectMode ? onSelect!(event) : null,
                      onTap: () => selectMode
                          ? onSelect!(event)
                          : hideKeyboardChatScreen?.call(),
                      child: Center(
                        child: Container(
                          margin: EdgeInsetsDirectional.only(
                            start: selected ? 0.0 : 8.0,
                          ),
                          padding: EdgeInsets.only(
                            right: selected
                                ? 0
                                : ownMessage ||
                                        responsiveUtils.isDesktop(context)
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

  Widget _placeHolderWidget(bool sameSender, bool ownMessage, Event event) {
    if (selectMode || event.room.isDirectChat) {
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

    return SizedBox(width: MessageStyle.avatarSize);
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
          if (selectMode)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start:
                      (selected || responsiveUtils.isDesktop(context)) ? 16 : 8,
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
}

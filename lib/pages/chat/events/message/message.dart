import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/chat/chat_horizontal_action_menu.dart';
import 'package:fluffychat/pages/chat/chat_view_body_style.dart';
import 'package:fluffychat/pages/chat/context_item_chat_action.dart';
import 'package:fluffychat/pages/chat/events/message/message_content_with_timestamp_builder.dart';
import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:fluffychat/pages/chat/events/message/multi_platform_message_container.dart';
import 'package:fluffychat/pages/chat/events/message/swipeable_message.dart';
import 'package:fluffychat/pages/chat/events/state_message.dart';
import 'package:fluffychat/pages/chat/events/verification_request_content.dart';
import 'package:fluffychat/pages/chat/sticky_timestamp_widget.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/utils/extension/event_status_custom_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/filtered_timeline_extension.dart';
import 'package:fluffychat/presentation/mixins/message_avatar_mixin.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/context_menu/context_menu_action.dart';
import 'package:fluffychat/widgets/swipeable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:inview_notifier_list/inview_notifier_list.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

typedef OnMenuAction = Function(
  BuildContext,
  ChatHorizontalActionMenu,
  Event,
  TapDownDetails,
);

typedef OnSwipe = void Function(SwipeDirection);

typedef OnHover = void Function(bool, Event);

typedef OnSelect = void Function(Event);

typedef OnTapAvatar = void Function(Event);

typedef OnScrollToEventId = void Function(String);

class Message extends StatefulWidget {
  final Event event;
  final Event? previousEvent;
  final Event? nextEvent;
  final String? markedUnreadLocation;
  final OnSelect? onSelect;
  final OnTapAvatar? onAvatarTap;
  final OnScrollToEventId? scrollToEventId;
  final OnSwipe? onSwipe;
  final OnHover? onHover;
  final ValueNotifier<String?> isHoverNotifier;
  final bool selected;
  final Timeline timeline;
  final List<ContextMenuItemChatAction> listHorizontalActionMenu;
  final OnMenuAction? onMenuAction;
  final bool selectMode;
  final VoidCallback? hideKeyboardChatScreen;
  final ContextMenuBuilder? menuChildren;
  final FocusNode? focusNode;
  final void Function(Event)? timestampCallback;
  final void Function(Event)? onLongPress;
  final List<ContextMenuAction> listAction;

  const Message(
    this.event, {
    this.previousEvent,
    this.nextEvent,
    this.onSelect,
    this.onAvatarTap,
    this.onHover,
    this.scrollToEventId,
    this.onSwipe,
    this.selected = false,
    this.hideKeyboardChatScreen,
    this.selectMode = true,
    required this.timeline,
    required this.isHoverNotifier,
    required this.listHorizontalActionMenu,
    this.menuChildren,
    super.key,
    this.onMenuAction,
    this.markedUnreadLocation,
    this.focusNode,
    this.timestampCallback,
    this.onLongPress,
    required this.listAction,
  });

  /// Indicates wheither the user may use a mouse instead
  /// of touchscreen.
  static bool useMouse = false;

  static final responsiveUtils = getIt.get<ResponsiveUtils>();

  @override
  State<Message> createState() => _MessageState();
}

class _MessageState extends State<Message> with MessageAvatarMixin {
  InViewState? inViewState;

  final inviewNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _initialInviewState();
    });
  }

  @override
  void dispose() {
    inViewState?.removeContext(context: context);
    inViewState?.removeListener(_inviewStateListener);
    inviewNotifier.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(Message oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event.eventId != widget.event.eventId) {
      inViewState?.removeContext(context: context);
      inViewState?.addContext(context: context, id: widget.event.eventId);
    }
  }

  void _initialInviewState() {
    if (!mounted) return;
    inViewState = InViewNotifierListCustom.of(context);
    inViewState?.addListener(_inviewStateListener);
    inViewState?.addContext(context: context, id: widget.event.eventId);
  }

  void _inviewStateListener() {
    _updateInViewNotifier(inViewState?.inView(widget.event.eventId));
    if (inViewState?.inView(widget.event.eventId) == true) {
      widget.timestampCallback?.call(widget.event);
    }
  }

  void _updateInViewNotifier(bool? inView) {
    try {
      inviewNotifier.value = inView ?? inviewNotifier.value;
    } on FlutterError catch (e) {
      Logs().d('_MessageState:: _updateInViewNotifier: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!{
          EventTypes.Message,
          EventTypes.Sticker,
          EventTypes.Encrypted,
          EventTypes.CallInvite,
        }.contains(widget.event.type)) {
          if (widget.event.type.startsWith('m.call.')) {
            return const SizedBox();
          }
          if (widget.event.isJoinedByRoomCreator()) {
            return const SizedBox();
          }
          return StateMessage(widget.event);
        }

        if (widget.event.type == EventTypes.Message &&
            widget.event.messageType == EventTypes.KeyVerificationRequest) {
          return VerificationRequestContent(
            event: widget.event,
            timeline: widget.timeline,
          );
        }

        final displayTime = widget.event.type == EventTypes.RoomCreate ||
            widget.nextEvent == null ||
            !widget.event.originServerTs
                .sameEnvironment(widget.nextEvent!.originServerTs);
        final rowMainAxisAlignment = widget.event.isOwnMessage
            ? MainAxisAlignment.end
            : MainAxisAlignment.start;

        final rowChildren = <Widget>[
          placeHolderWidget(
            widget.onAvatarTap,
            event: widget.event,
            sameSender: widget.event.isSameSenderWith(widget.previousEvent),
            ownMessage: widget.event.isOwnMessage,
            context: context,
            selectMode: widget.selectMode,
          ),
          Expanded(
            child: MessageContentWithTimestampBuilder(
              event: widget.event,
              nextEvent: widget.nextEvent,
              onSelect: widget.onSelect,
              scrollToEventId: widget.scrollToEventId,
              selected: widget.selected,
              selectMode: widget.selectMode,
              timeline: widget.timeline,
              isHoverNotifier: widget.isHoverNotifier,
              listHorizontalActionMenu: widget.listHorizontalActionMenu,
              onMenuAction: widget.onMenuAction,
              menuChildren: widget.menuChildren,
              focusNode: widget.focusNode,
              onLongPress: widget.onLongPress,
              listActions: widget.listAction,
            ),
          ),
        ];
        final row = Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: rowMainAxisAlignment,
          children: rowChildren,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (displayTime)
              ValueListenableBuilder(
                valueListenable: inviewNotifier,
                builder: (context, inView, _) {
                  return StickyTimestampWidget(
                    content: !inView
                        ? widget.event.originServerTs.relativeTime(context)
                        : '',
                  );
                },
              ),
            if (widget.markedUnreadLocation != null &&
                widget.markedUnreadLocation == widget.event.eventId) ...[
              Padding(
                padding: MessageStyle.paddingDividerUnreadMessage,
                child: Divider(
                  height: MessageStyle.heightDivider,
                  color: LinagoraStateLayer(
                    LinagoraSysColors.material().surfaceTint,
                  ).opacityLayer3,
                ),
              ),
              StickyTimestampWidget(
                content: L10n.of(context)!.unreadMessages,
              ),
            ],
            MultiPlatformsMessageContainer(
              onTap: widget.hideKeyboardChatScreen,
              onHover: (hover) {
                if (!widget.event.status.isAvailable) {
                  return;
                }
                if (widget.onHover != null) {
                  widget.onHover!(hover, widget.event);
                }
              },
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: ChatViewBodyStyle.chatScreenMaxWidth,
                ),
                padding: MessageStyle.paddingMessage,
                alignment: Alignment.bottomCenter,
                child: SwipeableMessage(
                  event: widget.event,
                  onSwipe: widget.onSwipe,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: widget.event.isOwnMessage
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onLongPress: () =>
                            widget.selectMode && widget.event.status.isAvailable
                                ? widget.onSelect!(widget.event)
                                : null,
                        onTap: () =>
                            widget.selectMode && widget.event.status.isAvailable
                                ? widget.onSelect!(widget.event)
                                : widget.hideKeyboardChatScreen?.call(),
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.only(
                              right: widget.selected
                                  ? 0
                                  : widget.event.isOwnMessage ||
                                          Message.responsiveUtils
                                              .isDesktop(context)
                                      ? 8.0
                                      : 16.0,
                              top: widget.selected ? 0 : 1.0,
                              bottom: widget.selected ? 0 : 1.0,
                            ),
                            child: _messageSelectedWidget(
                              context,
                              row,
                              widget.event,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _messageSelectedWidget(
    BuildContext context,
    Widget child,
    Event event,
  ) {
    return Container(
      padding: EdgeInsets.only(
        left: Message.responsiveUtils.isMobile(context) ? 8.0 : 0,
      ),
      color: widget.selected
          ? LinagoraSysColors.material().secondaryContainer
          : Theme.of(context).primaryColor.withAlpha(0),
      constraints:
          const BoxConstraints(maxWidth: TwakeThemes.columnWidth * 2.5),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          if (widget.selectMode && event.status.isAvailable)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Icon(
                widget.selected
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: widget.selected
                    ? LinagoraSysColors.material().primary
                    : Colors.black,
                size: 20,
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

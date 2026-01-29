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
import 'package:fluffychat/pages/chat/optional_gesture_detector.dart';
import 'package:fluffychat/pages/chat/optional_padding.dart';
import 'package:fluffychat/pages/chat/optional_selection_container_disabled.dart';
import 'package:fluffychat/pages/chat/sticky_timestamp_widget.dart';
import 'package:fluffychat/presentation/mixins/message_avatar_mixin.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/utils/extension/event_status_custom_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/filtered_timeline_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/context_menu/context_menu_action.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/swipeable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_emoji_mart/flutter_emoji_mart.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:inview_notifier_list/inview_notifier_list.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:visibility_detector/visibility_detector.dart';

typedef OnMenuAction = Function(
  BuildContext,
  ChatHorizontalActionMenu,
  Event,
  TapDownDetails,
);

typedef OnSendEmojiReactionAction = void Function(
  String emoji,
  Event event,
);

typedef OnRemoveEmojiReactionAction = void Function(
  String emoji,
  Event event,
);

typedef OnPickEmojiReactionAction = void Function();

typedef OnSwipe = void Function(SwipeDirection);

typedef OnHover = void Function(bool, Event);

typedef OnSelect = void Function(Event);

typedef OnTapAvatar = void Function(Event);

typedef OnScrollToEventId = void Function(String);

class Message extends StatefulWidget {
  final Event event;
  final MatrixState? matrixState;
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
  final double maxWidth;
  final void Function(Event)? timestampCallback;
  final void Function(Event)? onEventVisible;
  final void Function(Event)? onLongPressMessage;
  final void Function()? onDisplayEmojiReaction;
  final void Function()? onHideEmojiReaction;
  final List<ContextMenuAction> listAction;
  final OnSendEmojiReactionAction? onSelectEmojiReaction;
  final OnPickEmojiReactionAction? onPickEmojiReaction;
  final void Function(Event)? onReply;
  final void Function(Event)? onEdit;
  final void Function(BuildContext, Event)? onDelete;
  final void Function(Event)? onForward;
  final void Function(Event)? onCopy;
  final void Function(Event)? onReport;
  final void Function(Event)? onPin;
  final void Function(Event)? onSaveToDownload;
  final void Function(Event)? onSaveToGallery;
  final void Function(BuildContext context, Event, TapDownDetails, double)?
      onTapMoreButton;
  final Future<Category?>? recentEmojiFuture;
  final Future<void> Function(Event)? onRetryTextMessage;

  const Message(
    this.event, {
    this.matrixState,
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
    required this.maxWidth,
    this.menuChildren,
    super.key,
    this.onMenuAction,
    this.markedUnreadLocation,
    this.focusNode,
    this.timestampCallback,
    this.onEventVisible,
    this.onDisplayEmojiReaction,
    this.onHideEmojiReaction,
    this.onLongPressMessage,
    required this.listAction,
    this.onSelectEmojiReaction,
    this.onPickEmojiReaction,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onForward,
    this.onCopy,
    this.onReport,
    this.onPin,
    this.onSaveToDownload,
    this.onSaveToGallery,
    this.onTapMoreButton,
    this.recentEmojiFuture,
    this.onRetryTextMessage,
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
    _initialInviewState();
  }

  @override
  void dispose() {
    inViewState?.removeContext(context: context);
    inViewState?.removeListener(_inviewStateListener);
    inViewState = null;
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
    try {
      inViewState = InViewNotifierCustomScrollView.of(context);
    } catch (e) {
      Logs().e('_initialInviewState: exception:', e);
    }
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

  void _onVisibilityChangedForMarkAsRead(VisibilityInfo info) {
    final currentFraction = info.visibleFraction;

    // Fire callback whenever message is >50% visible
    // The debouncer in AutoMarkAsReadMixin handles deduplication
    if (currentFraction >= 0.5) {
      widget.onEventVisible?.call(widget.event);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!{
      EventTypes.Message,
      EventTypes.Sticker,
      EventTypes.Encrypted,
      EventTypes.CallInvite,
    }.contains(widget.event.type)) {
      if (widget.event.type.startsWith('m.call.')) {
        return const SizedBox.shrink();
      }
      if (widget.event.isJoinedByRoomCreator()) {
        return const SizedBox.shrink();
      }
      return OptionalSelectionContainerDisabled(
        isEnabled: PlatformInfos.isWeb,
        child: StateMessage(widget.event),
      );
    }

    if (widget.event.type == EventTypes.Message &&
        widget.event.messageType == EventTypes.KeyVerificationRequest) {
      return OptionalSelectionContainerDisabled(
        isEnabled: PlatformInfos.isWeb,
        child: VerificationRequestContent(
          event: widget.event,
          timeline: widget.timeline,
        ),
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
      if (!widget.event.shouldAlignOwnMessageInDifferentSide)
        OptionalSelectionContainerDisabled(
          isEnabled: PlatformInfos.isWeb,
          child: placeHolderWidget(
            widget.onAvatarTap,
            event: widget.event,
            sameSender: widget.event.isSameSenderWith(widget.previousEvent),
            ownMessage: widget.event.isOwnMessage,
            context: context,
            selectMode: widget.selectMode,
          ),
        ),
      Expanded(
        child: MessageContentWithTimestampBuilder(
          event: widget.event,
          matrixState: widget.matrixState,
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
          maxWidth: widget.maxWidth,
          onDisplayEmojiReaction: widget.onDisplayEmojiReaction,
          onHideEmojiReaction: widget.onHideEmojiReaction,
          listActions: widget.listAction,
          onSendEmojiReaction: widget.onSelectEmojiReaction,
          onPickEmojiReaction: widget.onPickEmojiReaction,
          onReply: widget.onReply,
          onEdit: widget.onEdit,
          onDelete: widget.onDelete,
          onForward: widget.onForward,
          onCopy: widget.onCopy,
          onReport: widget.onReport,
          onLongPressMessage: widget.onLongPressMessage,
          onPin: widget.onPin,
          saveToDownload: widget.onSaveToDownload,
          saveToGallery: widget.onSaveToGallery,
          onTapMoreButton: widget.onTapMoreButton,
          recentEmojiFuture: widget.recentEmojiFuture,
          onRetryTextMessage: widget.onRetryTextMessage,
        ),
      ),
    ];
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: rowMainAxisAlignment,
      children: rowChildren,
    );
    final column = Column(
      crossAxisAlignment: MessageStyle.messageCrossAxisAlignment(
        widget.event,
        context,
      ),
      children: [
        if (displayTime)
          ValueListenableBuilder(
            valueListenable: inviewNotifier,
            builder: (context, inView, _) {
              return OptionalSelectionContainerDisabled(
                isEnabled: PlatformInfos.isWeb,
                child: StickyTimestampWidget(
                  content: !inView
                      ? widget.event.originServerTs.relativeTime(context)
                      : '',
                ),
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
          OptionalSelectionContainerDisabled(
            isEnabled: PlatformInfos.isWeb,
            child: StickyTimestampWidget(
              content: L10n.of(context)!.unreadMessages,
            ),
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
              child: OptionalGestureDetector(
                onLongPress: () => widget.onSelect!(widget.event),
                onTap: () => widget.onSelect!(widget.event),
                isEnabled: widget.selectMode && widget.event.status.isAvailable,
                child: OptionalPadding(
                  padding: EdgeInsetsDirectional.only(
                    end: widget.event.isOwnMessage ||
                            Message.responsiveUtils.isDesktop(context)
                        ? 8.0
                        : 16.0,
                    top: 1.0,
                    bottom: 1.0,
                  ),
                  isEnabled: !widget.selected,
                  child: _messageSelectedWidget(
                    context,
                    row,
                    widget.event,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    return VisibilityDetector(
      key: Key('visibility_${widget.event.eventId}'),
      onVisibilityChanged: _onVisibilityChangedForMarkAsRead,
      child: column,
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
          if (widget.selectMode && event.redacted)
            const SizedBox(width: 20)
          else if (widget.selectMode && event.status.isAvailable)
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

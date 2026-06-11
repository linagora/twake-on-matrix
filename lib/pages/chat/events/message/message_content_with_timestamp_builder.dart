import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/pages/chat/chat_horizontal_action_menu.dart';
import 'package:fluffychat/pages/chat/events/message/display_name_widget.dart';
import 'package:fluffychat/pages/chat/events/message/message.dart';
import 'package:fluffychat/pages/chat/events/message/message_content_builder.dart';
import 'package:fluffychat/pages/chat/events/message/message_context_menu_action.dart';
import 'package:fluffychat/pages/chat/events/message/message_reaction_dialog.dart';
import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:fluffychat/pages/chat/events/message/multi_platform_message_container.dart';
import 'package:fluffychat/pages/chat/events/message_reactions.dart';
import 'package:fluffychat/pages/chat/events/message_time.dart';
import 'package:fluffychat/pages/chat/optional_selection_container_disabled.dart';
import 'package:fluffychat/pages/chat/optional_stack.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/context_menu/context_menu_action.dart';
import 'package:fluffychat/widgets/context_menu/context_menu_action_item.dart';
import 'package:fluffychat/widgets/context_menu/twake_context_menu_area.dart';
import 'package:fluffychat/widgets/mixins/twake_context_menu_mixin.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_emoji_mart/flutter_emoji_mart.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:overflow_view/overflow_view.dart';
import 'package:pull_down_button/pull_down_button.dart';

typedef ContextMenuBuilder = List<Widget> Function(BuildContext context);

class MessageContentWithTimestampBuilder extends StatefulWidget {
  final Event event;
  final MatrixState? matrixState;
  final Event? nextEvent;
  final Event? previousEvent;
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
  final double maxWidth;
  final List<ContextMenuAction> listActions;
  final OnSendEmojiReactionAction? onSendEmojiReaction;
  final OnPickEmojiReactionAction? onPickEmojiReaction;
  final void Function(Event)? onLongPressMessage;
  final void Function(Event)? onReply;
  final void Function(Event)? onEdit;
  final void Function(BuildContext, Event)? onDelete;
  final void Function(Event)? onForward;
  final void Function(Event)? onCopy;
  final void Function(Event)? onReport;
  final void Function(Event)? onPin;
  final void Function(Event)? saveToDownload;
  final void Function(Event)? saveToGallery;
  final void Function(BuildContext context, Event, TapDownDetails, double)?
  onTapMoreButton;
  final Future<Category?>? recentEmojiFuture;
  final Future<void> Function(Event)? onRetryTextMessage;

  static const Key dialogSafeAreaKey = Key(
    'message_context_menu_dialog_safe_area',
  );

  const MessageContentWithTimestampBuilder({
    super.key,
    required this.event,
    this.matrixState,
    this.nextEvent,
    this.previousEvent,
    this.onSelect,
    this.scrollToEventId,
    this.onDisplayEmojiReaction,
    this.onHideEmojiReaction,
    this.selected = false,
    this.selectMode = true,
    required this.timeline,
    required this.isHoverNotifier,
    required this.listHorizontalActionMenu,
    required this.maxWidth,
    this.onMenuAction,
    this.menuChildren,
    this.focusNode,
    required this.listActions,
    this.onSendEmojiReaction,
    this.onPickEmojiReaction,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onForward,
    this.onCopy,
    this.onReport,
    this.onLongPressMessage,
    this.onPin,
    this.saveToDownload,
    this.saveToGallery,
    this.onTapMoreButton,
    this.recentEmojiFuture,
    this.onRetryTextMessage,
  });

  @override
  State<MessageContentWithTimestampBuilder> createState() =>
      _MessageContentWithTimestampBuilderState();
}

class _MessageContentWithTimestampBuilderState
    extends State<MessageContentWithTimestampBuilder>
    with TwakeContextMenuMixin {
  final ValueNotifier<bool> _displayEmojiPicker = ValueNotifier(false);
  final ResponsiveUtils _responsiveUtils = getIt.get<ResponsiveUtils>();
  bool someHorizontalActionHidden = false;

  List<MessageContextMenuAction> _messageContextMenu(Event event) => [
    if (event.room.canSendDefaultMessages) ...[MessageContextMenuAction.reply],
    MessageContextMenuAction.forward,
    MessageContextMenuAction.copy,
    if (event.room.canReportContent) MessageContextMenuAction.report,
    if (event.canEditEvents(widget.matrixState)) ...[
      MessageContextMenuAction.edit,
    ],
    MessageContextMenuAction.select,
    MessageContextMenuAction.pin,
    if (PlatformInfos.isAndroid) ...[
      if (event.hasAttachment && !event.isVideoOrImage)
        MessageContextMenuAction.saveToDownload,
    ],
    if (event.isVideoOrImage && !PlatformInfos.isWeb)
      MessageContextMenuAction.saveToGallery,
    if (event.canDelete) MessageContextMenuAction.delete,
  ];

  List<MessageContextMenuAction> _errorMessageContextMenu(Event event) => [
    if (event.isCopyable) MessageContextMenuAction.copy,
    if (event.canDelete) MessageContextMenuAction.delete,
  ];

  @override
  void dispose() {
    _displayEmojiPicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayTime =
        widget.event.type == EventTypes.RoomCreate ||
        widget.nextEvent == null ||
        !widget.event.originServerTs.sameEnvironment(
          widget.nextEvent!.originServerTs,
        );

    final timelineText =
        {
          MessageTypes.Text,
          MessageTypes.BadEncrypted,
        }.contains(widget.event.messageType) ||
        widget.event.isCaptionModeOrReply();

    return Align(
      alignment: MessageStyle.messageAlignmentGeometry(widget.event, context),
      child: _messageContentWithTimestampBuilder(
        context: context,
        displayTime: displayTime,
        timelineText: timelineText,
      ),
    );
  }

  Widget _messageContentWithTimestampBuilder({
    required BuildContext context,
    required bool displayTime,
    required bool timelineText,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MessageStyle.messageAlignment(widget.event, context),
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.event.shouldDisplayContextMenuInLeftBubble &&
            !_responsiveUtils.isMobile(context) &&
            !widget.event.redacted)
          _menuActionsRowBuilder(context, isReversed: true),
        TwakeContextMenuArea(
          builder: widget.menuChildren != null
              ? (context) => widget.menuChildren!.call(context)
              : null,
          listActions: widget.listActions,
          child: Container(
            alignment: widget.event.isOwnMessage
                ? Alignment.topRight
                : Alignment.topLeft,
            padding: MessageStyle.paddingMessageContainer(
              displayTime,
              context,
              widget.nextEvent,
              widget.event,
              widget.selected,
            ),
            child: MultiPlatformSelectionMode(
              event: widget.event,
              isClickable: _responsiveUtils.isMobile(context),
              onLongPress: widget.event.redacted
                  ? null
                  : widget.event.status.isError
                  ? (event) => _handleErrorMessageLongPress(
                      context,
                      event,
                      timelineText: timelineText,
                    )
                  : !widget.event.status.isError &&
                        !widget.event.status.isSending
                  ? (event) => _handleAvailableMessageLongPress(
                      context,
                      event,
                      timelineText: timelineText,
                    )
                  : null,
              child: _messageBuilder(
                context: context,
                timelineText: timelineText,
              ),
            ),
          ),
        ),
        if (widget.event.shouldDisplayContextMenuInRightBubble &&
            !_responsiveUtils.isMobile(context) &&
            !widget.event.redacted)
          _menuActionsRowBuilder(context),
      ],
    );
  }

  /// Wraps the message preview for a hero dialog with selection/scroll support.
  Widget _buildHeroPreviewMessage({
    required BuildContext context,
    required String keyPrefix,
    required bool timelineText,
  }) {
    return Material(
      color: Colors.transparent,
      child: SelectionArea(
        child: SingleChildScrollView(
          primary: true,
          physics: const ClampingScrollPhysics(),
          child: _messageBuilder(
            key: ValueKey(
              '$keyPrefix%${DateTime.now().millisecondsSinceEpoch}',
            ),
            context: context,
            timelineText: timelineText,
          ),
        ),
      ),
    );
  }

  /// Opens the hero emoji reaction dialog for available messages.
  Future<void> _handleAvailableMessageLongPress(
    BuildContext context,
    Event event, {
    required bool timelineText,
  }) async {
    // for pin screen
    if (widget.onLongPressMessage != null) {
      widget.onLongPressMessage?.call(event);
      return;
    }
    // for chat screen
    widget.onDisplayEmojiReaction?.call();
    _displayEmojiPicker.value = false;
    await Navigator.of(context)
        .push(
          HeroDialogRoute(
            builder: (context) => MessageReactionDialog(
              event: event,
              timeline: widget.timeline,
              displayEmojiPicker: _displayEmojiPicker,
              dialogSafeAreaKey:
                  MessageContentWithTimestampBuilder.dialogSafeAreaKey,
              messageWidget: _buildHeroPreviewMessage(
                context: context,
                keyPrefix: 'PreviewReactionWidgetKey',
                timelineText: timelineText,
              ),
              emojiPickerBuilder: _emojiPickerBuilder,
              messageContextMenu: _messageContextMenu,
              themeContextMenu: _themeContextMenu,
              iconContextMenu: _iconContextMenu,
              onSendEmojiReaction: widget.onSendEmojiReaction,
            ),
          ),
        )
        .then((result) {
          _handleResultFromHeroPage(context, result);
          widget.onHideEmojiReaction?.call();
        });
  }

  /// Opens the hero dialog for error messages (no emoji reactions).
  Future<void> _handleErrorMessageLongPress(
    BuildContext context,
    Event event, {
    required bool timelineText,
  }) async {
    widget.onDisplayEmojiReaction?.call();
    _displayEmojiPicker.value = false;
    await Navigator.of(context)
        .push(
          HeroDialogRoute(
            builder: (context) => MessageReactionDialog(
              event: event,
              timeline: widget.timeline,
              displayEmojiPicker: _displayEmojiPicker,
              dialogSafeAreaKey:
                  MessageContentWithTimestampBuilder.dialogSafeAreaKey,
              showReactions: false,
              messageWidget: _buildHeroPreviewMessage(
                context: context,
                keyPrefix: 'PreviewErrorWidgetKey',
                timelineText: timelineText,
              ),
              emojiPickerBuilder: _emojiPickerBuilder,
              messageContextMenu: _errorMessageContextMenu,
              themeContextMenu: _themeContextMenu,
              iconContextMenu: _iconContextMenu,
            ),
          ),
        )
        .then((result) {
          _handleResultFromHeroPage(context, result);
          widget.onHideEmojiReaction?.call();
        });
  }

  void _handleResultFromHeroPage(BuildContext context, dynamic result) {
    if (result is String) {
      switch (result) {
        case 'reply':
          widget.onReply?.call(widget.event);
          break;
        case 'forward':
          widget.onForward?.call(widget.event);
          break;
        case 'copy':
          widget.onCopy?.call(widget.event);
          break;
        case 'report':
          widget.onReport?.call(widget.event);
          break;
        case 'select':
          widget.onSelect?.call(widget.event);
          break;
        case 'pin':
          widget.onPin?.call(widget.event);
          break;
        case 'saveToDownload':
          widget.saveToDownload?.call(widget.event);
          break;
        case 'saveToGallery':
          widget.saveToGallery?.call(widget.event);
          break;
        case 'edit':
          widget.onEdit?.call(widget.event);
          break;
        case 'delete':
          widget.onDelete?.call(context, widget.event);
          break;
      }
    }
    widget.onHideEmojiReaction?.call();
  }

  Widget _emojiPickerBuilder({
    required EmojiData emojiData,
    required Event? myReaction,
    required Event event,
    required dynamic relatesTo,
  }) {
    final linagoraRefColors = LinagoraRefColors.material();
    final textTheme = Theme.of(context).textTheme;
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        width: 326,
        height: 360,
        padding: const .all(12),
        decoration: BoxDecoration(
          color: linagoraRefColors.primary[100],
          borderRadius: BorderRadius.circular(24),
        ),
        child: EmojiPicker(
          emojiData: emojiData,
          recentEmoji: widget.recentEmojiFuture,
          configuration: EmojiPickerConfiguration(
            emojiStyle: textTheme.headlineLarge!,
            searchEmptyTextStyle: textTheme.labelMedium!.copyWith(
              color: linagoraRefColors.tertiary[30],
            ),
            searchEmptyWidget: SvgPicture.asset(ImagePaths.icSearchEmojiEmpty),
            searchFocusNode: FocusNode(),
            showRecentTab: true,
          ),
          itemBuilder: (context, emojiId, emoji, callback) {
            return MouseRegion(
              onHover: (_) {},
              child: EmojiItem(
                onTap: () {
                  callback(emojiId, emoji);
                },
                emoji: emoji,
                textStyle: textTheme.headlineLarge!,
              ),
            );
          },
          onEmojiSelected: (emojiId, emoji) =>
              _handleEmojiSelectionFromEmojiPicker(
                emoji: emoji,
                myReaction: myReaction,
                event: event,
                relatesTo: relatesTo,
              ),
        ),
      ),
    );
  }

  Widget _messageBuilder({
    Key? key,
    required BuildContext context,
    required bool timelineText,
  }) {
    final hasReactionEvent = widget.event.hasReactionEvent(
      timeline: widget.timeline,
    );

    final isDisplayOnlyEmoji = widget.event.isDisplayOnlyEmoji(widget.timeline);
    // The tail is shown on the last bubble of a same-sender group. A group
    // ends below when the sender changes or a date separator breaks it
    // (see [Event.isSameSenderWith]).
    final hasSameSenderBelow = !widget.event.isSameSenderWith(
      widget.previousEvent,
    );
    final showTail = !isDisplayOnlyEmoji && !hasSameSenderBelow;
    final alignOwnMessageRight =
        widget.event.isOwnMessage &&
        _responsiveUtils.enableRightAndLeftMessageAlignment(context);
    final tailDirection = showTail
        ? (alignOwnMessageRight
              ? BubbleTailDirection.right
              : BubbleTailDirection.left)
        : BubbleTailDirection.none;
    final showDisplayName = !_hideDisplayName(context);
    // Media without caption/reply uses the tighter media padding
    final isMediaOnly =
        widget.event.isVideoOrImage && !timelineText && !showDisplayName;
    final bubbleContentType = isMediaOnly
        ? BubbleContentType.mediaOnly
        : BubbleContentType.other;
    final bubbleConstraints = BoxConstraints(
      maxWidth: MessageStyle.messageBubbleWidth(
        context,
        event: widget.event,
        maxWidthScreen: widget.maxWidth,
      ),
    );
    final bubbleContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDisplayName)
          OptionalSelectionContainerDisabled(
            isEnabled: PlatformInfos.isWeb,
            child: DisplayNameWidget(event: widget.event),
          ),
        OptionalStack(
          isEnabled: timelineText,
          alignment: AlignmentDirectional.bottomEnd,
          children: [
            MessageContentBuilder(
              event: widget.event,
              timeline: widget.timeline,
              onSelect: widget.onSelect,
              nextEvent: widget.nextEvent,
              scrollToEventId: widget.scrollToEventId,
              selectMode: widget.selectMode,
              onRetryTextMessage: widget.onRetryTextMessage,
            ),
            if (!widget.event.isReplyEventWithAudio())
              OptionalSelectionContainerDisabled(
                isEnabled: PlatformInfos.isWeb,
                child: Padding(
                  padding: MessageStyle.paddingMessageTime,
                  child: Text.rich(
                    WidgetSpan(
                      child: MessageTime(
                        timelineOverlayMessage:
                            widget.event.timelineOverlayMessage,
                        room: widget.event.room,
                        event: widget.event,
                        showSeenIcon: widget.event.isOwnMessage,
                        timeline: widget.timeline,
                        onRetryTextMessage: widget.onRetryTextMessage,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );

    return OptionalStack(
      key: key,
      alignment: widget.event.isOwnMessage
          ? AlignmentDirectional.bottomStart
          : AlignmentDirectional.bottomEnd,
      isEnabled: hasReactionEvent,
      children: [
        if (isDisplayOnlyEmoji)
          Container(constraints: bubbleConstraints, child: bubbleContent)
        else
          MessageBubble(
            isOwnMessage: widget.event.isOwnMessage,
            tailDirection: tailDirection,
            hasReactions: hasReactionEvent,
            contentType: bubbleContentType,
            constraints: bubbleConstraints,
            child: bubbleContent,
          ),
        PositionedDirectional(
          start: 8,
          end: 0,
          bottom: 0,
          child: OptionalSelectionContainerDisabled(
            isEnabled: PlatformInfos.isWeb,
            child: MessageReactions(widget.event, widget.timeline),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  bool _hideDisplayName(BuildContext context) {
    return widget.event.hideDisplayName(
      widget.nextEvent,
      _responsiveUtils.isMobile(context),
    );
  }

  Future<void> _handleEmojiSelectionFromEmojiPicker({
    required String emoji,
    required Event? myReaction,
    required Event event,
    required dynamic relatesTo,
  }) async {
    final isSelected = emoji == (relatesTo?['key'] ?? '');
    if (myReaction == null) {
      Navigator.of(context).pop();
      widget.onSendEmojiReaction?.call(emoji, event);
      return;
    }

    if (isSelected) {
      Navigator.of(context).pop();
      await myReaction.redactEvent();
      return;
    }

    if (!isSelected) {
      Navigator.of(context).pop();
      await myReaction.redactEvent();
      widget.onSendEmojiReaction?.call(emoji, event);
      return;
    }
  }

  Widget _menuActionsRowBuilder(
    BuildContext context, {
    bool isReversed = false,
  }) {
    final listHorizontalActionMenu = isReversed
        ? widget.listHorizontalActionMenu.reversed.toList()
        : widget.listHorizontalActionMenu;
    return Flexible(
      child: ValueListenableBuilder(
        valueListenable: widget.isHoverNotifier,
        builder: (context, isHover, child) {
          if (isHover != null &&
              isHover == widget.event.eventId &&
              !widget.event.redacted) {
            return child!;
          }
          return const SizedBox.shrink();
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: .circular(24),
          ),
          alignment: isReversed
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          padding: isReversed
              ? const EdgeInsetsDirectional.only(end: 8)
              : const EdgeInsetsDirectional.only(start: 8),
          child: OverflowView.flexible(
            reverse: !isReversed,
            spacing: 8,
            builder: (context, remainingItemCount) {
              someHorizontalActionHidden = remainingItemCount != 0;
              return const SizedBox();
            },
            children: listHorizontalActionMenu.map((item) {
              return TwakeIconButton(
                onTapDown: (tapDownDetails) {
                  if (someHorizontalActionHidden &&
                      item.action == ChatHorizontalActionMenu.more) {
                    return widget.onTapMoreButton?.call(
                      context,
                      widget.event,
                      tapDownDetails,
                      widget.maxWidth,
                    );
                  }
                  widget.onMenuAction?.call(
                    context,
                    item.action,
                    widget.event,
                    tapDownDetails,
                  );
                },
                icon: item.action.getIcon(),
                imagePath: item.action.getImagePath(),
                tooltip: item.action.getTitle(context),
                preferBelow: false,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Color? _textContextMenuColor(MessageContextMenuAction action) {
    return action == MessageContextMenuAction.delete
        ? LinagoraSysColors.material().error
        : LinagoraRefColors.material().neutral[30];
  }

  PullDownMenuItemTheme _themeContextMenu(MessageContextMenuAction action) {
    return PullDownMenuItemTheme(
      textStyle: context.textTheme.bodyLarge!.copyWith(
        color: _textContextMenuColor(action),
      ),
    );
  }

  Widget? _iconContextMenu(Event event, MessageContextMenuAction item) {
    return item.imagePath(event) != null
        ? SvgPicture.asset(
            item.imagePath(event) ?? '',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              LinagoraRefColors.material().neutral[30]!,
              BlendMode.srcIn,
            ),
          )
        : null;
  }
}

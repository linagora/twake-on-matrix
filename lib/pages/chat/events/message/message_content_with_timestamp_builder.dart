import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/model/room/room_extension.dart';
import 'package:twake_chat/pages/chat/chat_horizontal_action_menu.dart';
import 'package:twake_chat/pages/chat/events/images_builder/media_album_scope.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/media_album_context_extension.dart';
import 'package:twake_chat/pages/chat/events/message/display_name_widget.dart';
import 'package:twake_chat/pages/chat/events/message/message.dart';
import 'package:twake_chat/pages/chat/events/message/message_content_builder.dart';
import 'package:twake_chat/pages/chat/events/message/message_context_menu_action.dart';
import 'package:twake_chat/pages/chat/events/message/message_reaction_dialog.dart';
import 'package:twake_chat/pages/chat/events/message/message_style.dart';
import 'package:twake_chat/pages/chat/events/message/multi_platform_message_container.dart';
import 'package:twake_chat/pages/chat/events/message_reactions.dart';
import 'package:twake_chat/pages/chat/events/message_time.dart';
import 'package:twake_chat/pages/chat/optional_selection_container_disabled.dart';
import 'package:twake_chat/pages/chat/optional_stack.dart';
import 'package:twake_chat/generated/assets.gen.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/utils/date_time_extension.dart';
import 'package:twake_chat/utils/extension/build_context_extension.dart';
import 'package:twake_chat/utils/manager/upload_manager/models/retry_upload_result.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_manager.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';
import 'package:twake_chat/widgets/context_menu/context_menu_action.dart';
import 'package:twake_chat/widgets/context_menu/context_menu_action_item.dart';
import 'package:twake_chat/widgets/context_menu/twake_context_menu_area.dart';
import 'package:twake_chat/widgets/mixins/twake_context_menu_mixin.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:twake_chat/widgets/twake_components/twake_icon_button.dart';
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
  final OnToggleEmojiReactionAction? onToggleEmojiReaction;
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

  /// Album actions, given every image of the album, oldest first.
  final void Function(List<Event>)? onForwardAlbum;
  final void Function(List<Event>)? onSaveAlbumToGallery;
  final void Function(BuildContext, List<Event>)? onDeleteAlbum;
  final void Function(List<Event>)? onReportAlbum;
  final void Function(List<Event>)? onSelectAlbum;
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
    this.onToggleEmojiReaction,
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
    this.onForwardAlbum,
    this.onSaveAlbumToGallery,
    this.onDeleteAlbum,
    this.onReportAlbum,
    this.onSelectAlbum,
    this.onTapMoreButton,
    this.recentEmojiFuture,
    this.onRetryTextMessage,
  });

  /// [members] when every one of them is sent; else null, so the album menu
  /// is not offered while an image is still uploading.
  @visibleForTesting
  static List<Event>? sentAlbumMembersOf(List<Event>? members) {
    if (members == null || members.any((member) => !member.status.isSent)) {
      return null;
    }
    return members;
  }

  /// The menu of an album: it acts on the whole album, as one message. The
  /// caption sits on the last image, so Copy and Edit need one there.
  @visibleForTesting
  static List<MessageContextMenuAction> albumContextMenuOf(
    List<Event> members, {
    required bool canReply,
    required bool canReport,
    required bool canEditCaption,
  }) {
    final hasCaption = members.last.isCaptionModeOrReply();
    return [
      if (canReply) MessageContextMenuAction.reply,
      MessageContextMenuAction.forward,
      if (hasCaption) MessageContextMenuAction.copy,
      if (canReport) MessageContextMenuAction.report,
      if (hasCaption && canEditCaption) MessageContextMenuAction.edit,
      MessageContextMenuAction.select,
      MessageContextMenuAction.selectAll,
      MessageContextMenuAction.pin,
      if (!PlatformInfos.isWeb) MessageContextMenuAction.saveToGallery,
      if (members.every((member) => member.canDelete))
        MessageContextMenuAction.delete,
    ];
  }

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

  /// The album image under the finger, so that a long-press on an album opens
  /// the menu of that image and not of the leader.
  Event? _pressedAlbumMember;

  Event _pressedOr(Event event) => _pressedAlbumMember ?? event;

  Widget _trackAlbumPress(Widget child) => Listener(
    onPointerUp: (_) => _pressedAlbumMember = null,
    onPointerCancel: (_) => _pressedAlbumMember = null,
    child: MediaAlbumPressScope<Event>(
      onPressed: (event) => _pressedAlbumMember = event,
      child: child,
    ),
  );

  /// [album]: the sent images of the album this bubble leads, read when the
  /// menu opens; null for a single message.
  List<MessageContextMenuAction> _messageContextMenu(
    Event event,
    List<Event>? album,
  ) {
    if (album == null) return _singleMessageContextMenu(event);
    return MessageContentWithTimestampBuilder.albumContextMenuOf(
      album,
      canReply: event.room.canSendDefaultMessages,
      canReport: event.room.canReportContent,
      canEditCaption: album.last.canEditEvents(widget.matrixState),
    );
  }

  List<MessageContextMenuAction> _singleMessageContextMenu(Event event) => [
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

  // TODO: [transitional]
  final UploadManager _uploadManager = getIt.get<UploadManager>();

  // A failed upload has no `url` yet, so `hasAttachment` is false.
  static const _uploadedMessageTypes = {
    MessageTypes.Image,
    MessageTypes.Video,
    MessageTypes.File,
  };

  List<MessageContextMenuAction> _errorMessageContextMenu(Event event) => [
    if (_uploadedMessageTypes.contains(event.messageType))
      MessageContextMenuAction.trySendAgain,
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
        context.albumHasCaptionOrReply(widget.event);

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
            child: _trackAlbumPress(
              MultiPlatformSelectionMode(
                event: widget.event,
                isClickable: _responsiveUtils.isMobile(context),
                onLongPress: widget.event.redacted
                    ? null
                    : widget.event.status.isError
                    ? (event) => _handleErrorMessageLongPress(
                        context,
                        _pressedOr(event),
                        timelineText: timelineText,
                      )
                    : !widget.event.status.isError &&
                          !widget.event.status.isSending
                    ? (event) => _handleAvailableMessageLongPress(
                        context,
                        _pressedOr(event),
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
    required List<Event>? albumMembers,
    required String keyPrefix,
    required bool timelineText,
  }) {
    return Material(
      color: Colors.transparent,
      child: SelectionArea(
        child: SingleChildScrollView(
          primary: true,
          physics: const ClampingScrollPhysics(),
          child: _withAlbumScope(
            albumMembers,
            Builder(
              builder: (context) => _messageBuilder(
                key: ValueKey(
                  '$keyPrefix%${DateTime.now().millisecondsSinceEpoch}',
                ),
                context: context,
                timelineText: timelineText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The dialog route sits above the album scope of the list, so the preview
  /// gets the [members] read from the bubble before the route opened.
  Widget _withAlbumScope(List<Event>? members, Widget preview) {
    if (members == null) return preview;
    return MediaAlbumScope<Event>(
      members: members,
      idOf: mediaAlbumEventId,
      child: preview,
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
    final albumMembers = context.albumMembersFor(widget.event);
    final album = MessageContentWithTimestampBuilder.sentAlbumMembersOf(
      albumMembers,
    );
    // An album is one message: its menu and reactions belong to the first
    // image; [event] is the pressed image, kept for Select.
    final menuEvent = album?.first ?? event;
    await Navigator.of(context)
        .push(
          HeroDialogRoute(
            builder: (context) => MessageReactionDialog(
              event: menuEvent,
              timeline: widget.timeline,
              displayEmojiPicker: _displayEmojiPicker,
              dialogSafeAreaKey:
                  MessageContentWithTimestampBuilder.dialogSafeAreaKey,
              messageWidget: _buildHeroPreviewMessage(
                albumMembers: albumMembers,
                keyPrefix: 'PreviewReactionWidgetKey',
                timelineText: timelineText,
              ),
              emojiPickerBuilder: _emojiPickerBuilder,
              messageContextMenu: (event) => _messageContextMenu(event, album),
              themeContextMenu: _themeContextMenu,
              iconContextMenu: _iconContextMenu,
              onToggleEmojiReaction: widget.onToggleEmojiReaction,
            ),
          ),
        )
        .then((result) {
          _handleResultFromHeroPage(context, result, event, album: album);
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
    final albumMembers = context.albumMembersFor(widget.event);
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
                albumMembers: albumMembers,
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
          _handleResultFromHeroPage(context, result, event);
          widget.onHideEmojiReaction?.call();
        });
  }

  Future<void> _retryUpload(BuildContext context, Event event) async {
    final result = await _uploadManager.retryUpload(event);
    if (!context.mounted) return;
    if (result == RetryUploadResult.fileDataUnavailable) {
      TwakeSnackBar.show(context, L10n.of(context)!.messageCannotBeResent);
    }
  }

  void _handleResultFromHeroPage(
    BuildContext context,
    dynamic result,
    Event event, {
    List<Event>? album,
  }) {
    if (result is String && album != null) {
      _handleAlbumResult(context, result, album, pressed: event);
    } else if (result is String) {
      switch (result) {
        case 'reply':
          widget.onReply?.call(event);
          break;
        case 'forward':
          widget.onForward?.call(event);
          break;
        case 'copy':
          widget.onCopy?.call(event);
          break;
        case 'report':
          widget.onReport?.call(event);
          break;
        case 'select':
          widget.onSelect?.call(event);
          break;
        case 'pin':
          widget.onPin?.call(event);
          break;
        case 'saveToDownload':
          widget.saveToDownload?.call(event);
          break;
        case 'saveToGallery':
          widget.saveToGallery?.call(event);
          break;
        case 'edit':
          widget.onEdit?.call(event);
          break;
        case 'delete':
          widget.onDelete?.call(context, event);
          break;
        case 'trySendAgain':
          _retryUpload(context, event);
          break;
      }
    }
    widget.onHideEmojiReaction?.call();
  }

  /// Routes a menu result of an album: reply and pin go to the first image,
  /// copy and edit to the caption (last image), Select to the [pressed]
  /// image, and the rest to every image.
  void _handleAlbumResult(
    BuildContext context,
    String result,
    List<Event> album, {
    required Event pressed,
  }) {
    switch (result) {
      case 'reply':
        widget.onReply?.call(album.first);
      case 'pin':
        widget.onPin?.call(album.first);
      case 'copy':
        widget.onCopy?.call(album.last);
      case 'edit':
        widget.onEdit?.call(album.last);
      case 'select':
        widget.onSelect?.call(pressed);
      case 'selectAll':
        widget.onSelectAlbum?.call(album);
      case 'forward':
        widget.onForwardAlbum?.call(album);
      case 'report':
        widget.onReportAlbum?.call(album);
      case 'saveToGallery':
        widget.onSaveAlbumToGallery?.call(album);
      case 'delete':
        widget.onDeleteAlbum?.call(context, album);
    }
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
            searchEmptyWidget: SvgPicture.asset(
              Assets.images.searchEmojiEmpty.path,
            ),
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
              _handleEmojiSelectionFromEmojiPicker(emoji: emoji, event: event),
        ),
      ),
    );
  }

  Widget _messageBuilder({
    Key? key,
    required BuildContext context,
    required bool timelineText,
  }) {
    final reactionEvents = _eventsWithReactions(context);
    final hasReactionEvent = reactionEvents.isNotEmpty;

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
                        timelineOverlayMessage: context.albumTimelineOverlayFor(
                          widget.event,
                        ),
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

    final reactions = hasReactionEvent
        ? OptionalSelectionContainerDisabled(
            isEnabled: PlatformInfos.isWeb,
            child: _reactionsOf(reactionEvents),
          )
        : null;

    if (isDisplayOnlyEmoji) {
      return MessageBubble.plain(
        key: key,
        constraints: bubbleConstraints,
        isAlignedToEnd: alignOwnMessageRight,
        reactions: reactions,
        child: bubbleContent,
      );
    }
    return MessageBubble(
      key: key,
      isOwnMessage: widget.event.isOwnMessage,
      tailDirection: tailDirection,
      contentType: bubbleContentType,
      constraints: bubbleConstraints,
      isAlignedToEnd: alignOwnMessageRight,
      reactions: reactions,
      child: bubbleContent,
    );
  }

  /// The events of this bubble that have reactions: every image of an album,
  /// so that a reaction on any of them is drawn.
  List<Event> _eventsWithReactions(BuildContext context) => [
    for (final event in context.albumEventsOf(widget.event))
      if (event.hasReactionEvent(timeline: widget.timeline)) event,
  ];

  /// One row: each image keeps its own chips, so a tap reacts to that image.
  Widget _reactionsOf(List<Event> events) {
    if (events.length == 1) {
      return MessageReactions(events.single, widget.timeline);
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final event in events) MessageReactions(event, widget.timeline),
        ],
      ),
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
    required Event event,
  }) async {
    Navigator.of(context).pop();
    await widget.onToggleEmojiReaction?.call(emoji, event);
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
                padding: const EdgeInsets.symmetric(
                  horizontal: LinagoraSpacing.base,
                ),
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

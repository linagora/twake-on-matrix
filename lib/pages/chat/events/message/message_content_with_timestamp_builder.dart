import 'dart:ui';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/pages/chat/events/message/display_name_widget.dart';
import 'package:fluffychat/pages/chat/events/message/message.dart';
import 'package:fluffychat/pages/chat/events/message/message_content_builder.dart';
import 'package:fluffychat/pages/chat/events/message/message_context_menu_action.dart';
import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:fluffychat/pages/chat/events/message/multi_platform_message_container.dart';
import 'package:fluffychat/pages/chat/events/message_reactions.dart';
import 'package:fluffychat/pages/chat/events/message_time.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:fluffychat/utils/extension/event_status_custom_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/context_menu/context_menu_action.dart';
import 'package:fluffychat/widgets/context_menu/context_menu_action_item.dart';
import 'package:fluffychat/widgets/context_menu/twake_context_menu_area.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_emoji_mart/flutter_emoji_mart.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
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
  final void Function(Event)? onEdit;
  final void Function(BuildContext, Event)? onDelete;
  final void Function(Event)? onForward;
  final void Function(Event)? onCopy;
  final void Function(Event)? onPin;
  final void Function(Event)? saveToDownload;
  final void Function(Event)? saveToGallery;
  final void Function(BuildContext context, Event, TapDownDetails)?
      onTapMoreButton;
  final Future<Category?>? recentEmojiFuture;

  static final responsiveUtils = getIt.get<ResponsiveUtils>();

  const MessageContentWithTimestampBuilder({
    super.key,
    required this.event,
    this.matrixState,
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
    this.onEdit,
    this.onDelete,
    this.onForward,
    this.onCopy,
    this.onLongPressMessage,
    this.onPin,
    this.saveToDownload,
    this.saveToGallery,
    this.onTapMoreButton,
    this.recentEmojiFuture,
  });

  @override
  State<MessageContentWithTimestampBuilder> createState() =>
      _MessageContentWithTimestampBuilderState();
}

class _MessageContentWithTimestampBuilderState
    extends State<MessageContentWithTimestampBuilder> {
  final ValueNotifier<bool> _displayEmojiPicker = ValueNotifier(false);

  List<MessageContextMenuAction> _messageContextMenu(Event event) => [
        if (event.room.canSendDefaultMessages) ...[
          MessageContextMenuAction.reply,
        ],
        MessageContextMenuAction.forward,
        MessageContextMenuAction.copy,
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

  @override
  Widget build(BuildContext context) {
    final displayTime = widget.event.type == EventTypes.RoomCreate ||
        widget.nextEvent == null ||
        !widget.event.originServerTs
            .sameEnvironment(widget.nextEvent!.originServerTs);
    final noBubble = {
          MessageTypes.Sticker,
        }.contains(widget.event.messageType) &&
        !widget.event.redacted;

    final timelineText = {
      MessageTypes.Text,
      MessageTypes.BadEncrypted,
    }.contains(widget.event.messageType);

    return Align(
      alignment: MessageStyle.messageAlignmentGeometry(
        widget.event,
        context,
      ),
      child: OverflowView.flexible(
        builder: (context, index) {
          return _messageContentWithTimestampBuilder(
            context: context,
            displayTime: displayTime,
            noBubble: noBubble,
            timelineText: timelineText,
            overlayContextMenu: true,
          );
        },
        children: [
          _messageContentWithTimestampBuilder(
            context: context,
            displayTime: displayTime,
            noBubble: noBubble,
            timelineText: timelineText,
          ),
        ],
      ),
    );
  }

  Widget _messageContentWithTimestampBuilder({
    required BuildContext context,
    required bool displayTime,
    required bool noBubble,
    required bool timelineText,
    bool overlayContextMenu = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MessageStyle.messageAlignment(widget.event, context),
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
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
              isClickable: MessageContentWithTimestampBuilder.responsiveUtils
                  .isMobile(context),
              onLongPress: widget.event.status.isAvailable
                  ? (event) async {
                      // for pin screen
                      if (widget.onLongPressMessage != null) {
                        widget.onLongPressMessage?.call(event);
                        return;
                      }
                      // for chat screen
                      widget.onDisplayEmojiReaction?.call();
                      _displayEmojiPicker.value = false;
                      await Navigator.of(context).push(
                        HeroDialogRoute(
                          builder: (context) {
                            final myReaction = event
                                .aggregatedEvents(
                                  widget.timeline,
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
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 80,
                                        sigmaY: 80,
                                      ),
                                      child: Container(
                                        color: const Color(
                                          0xFF636363,
                                        ).withOpacity(0.2),
                                      ),
                                    ),
                                  ),
                                  ValueListenableBuilder(
                                    valueListenable: _displayEmojiPicker,
                                    builder: (context, display, child) {
                                      return ReactionsDialogWidget(
                                        messageWidget: Material(
                                          color: widget.event.isOwnMessage
                                              ? LinagoraRefColors.material()
                                                  .primary[95]
                                              : MessageContentWithTimestampBuilder
                                                      .responsiveUtils
                                                      .isMobile(context)
                                                  ? LinagoraSysColors.material()
                                                      .onPrimary
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .surfaceContainerHighest,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                MessageStyle.bubbleBorderRadius,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius: MessageStyle
                                                  .bubbleBorderRadius,
                                              border: !widget
                                                          .event.isOwnMessage &&
                                                      MessageContentWithTimestampBuilder
                                                          .responsiveUtils
                                                          .isMobile(context)
                                                  ? Border.all(
                                                      color: MessageStyle
                                                          .borderColorReceivedBubble,
                                                    )
                                                  : null,
                                            ),
                                            child: SingleChildScrollView(
                                              primary: true,
                                              physics:
                                                  const ClampingScrollPhysics(),
                                              child: _messageBuilder(
                                                key: ValueKey(
                                                  'PreviewReactionWidgetKey%${DateTime.now().millisecondsSinceEpoch}',
                                                ),
                                                mainAxisSize: MainAxisSize.min,
                                                context: context,
                                                timelineText: timelineText,
                                                noBubble: noBubble,
                                                displayTime: displayTime,
                                                paddingBubble: EdgeInsets.zero,
                                                enableBorder: false,
                                              ),
                                            ),
                                          ),
                                        ),
                                        reactionWidget:
                                            !event.room.canSendReactions
                                                ? const SizedBox.shrink()
                                                : display
                                                    ? _emojiPickerBuilder(
                                                        emojiData:
                                                            Matrix.of(context)
                                                                .emojiData,
                                                        myReaction: myReaction,
                                                        event: event,
                                                        relatesTo: relatesTo,
                                                      )
                                                    : null,
                                        isOwnMessage: event.isOwnMessage,
                                        emojis: AppConfig.emojisDefault,
                                        enableMoreEmojiWidget: true,
                                        onPickEmojiReactionAction: () {
                                          _displayEmojiPicker.value = true;
                                        },
                                        myEmojiReacted: relatesTo?['key'] ?? '',
                                        onClickEmojiReactionAction:
                                            (emoji) async {
                                          final isSelected = emoji ==
                                              (relatesTo?['key'] ?? '');
                                          if (myReaction == null) {
                                            widget.onSendEmojiReaction
                                                ?.call(emoji, event);
                                            return;
                                          }

                                          if (isSelected) {
                                            await myReaction.redactEvent();
                                            return;
                                          }

                                          if (!isSelected) {
                                            await myReaction.redactEvent();
                                            widget.onSendEmojiReaction
                                                ?.call(emoji, event);
                                            return;
                                          }
                                        },
                                        contextMenuWidget: display
                                            ? const SizedBox()
                                            : Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 16,
                                                ),
                                                child: PullDownMenu(
                                                  routeTheme:
                                                      PullDownMenuRouteTheme(
                                                    backgroundColor:
                                                        LinagoraRefColors
                                                                .material()
                                                            .primary[100],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      20,
                                                    ),
                                                  ),
                                                  items: _messageContextMenu(
                                                    event,
                                                  )
                                                      .map(
                                                        (item) =>
                                                            PullDownMenuItem(
                                                          title: item.getTitle(
                                                            context,
                                                            event,
                                                          ),
                                                          itemTheme:
                                                              _themeContextMenu(
                                                            item,
                                                          ),
                                                          icon: item
                                                              .getIcon(event),
                                                          onTap: () => item
                                                              .onTap(context),
                                                          iconWidget:
                                                              _iconContextMenu(
                                                            event,
                                                            item,
                                                          ),
                                                          iconColor:
                                                              item.getIconColor(
                                                            context,
                                                            event,
                                                          ),
                                                        ),
                                                      )
                                                      .toList(),
                                                ),
                                              ),
                                        widgetAlignment: event.isOwnMessage
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ).then((result) {
                        _handleResultFromHeroPage(context, result);
                        widget.onHideEmojiReaction?.call();
                      });
                    }
                  : null,
              child: _messageBuilder(
                context: context,
                timelineText: timelineText,
                noBubble: noBubble,
                displayTime: displayTime,
              ),
            ),
          ),
        ),
        if (widget.event.status.isAvailable) ...[
          if (overlayContextMenu) ...[
            Container(
              padding: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TwakeIconButton(
                onTapDown: (tapDownDetails) => widget.onTapMoreButton?.call(
                  context,
                  widget.event,
                  tapDownDetails,
                ),
                icon: Icons.more_horiz,
                tooltip: L10n.of(context)!.more,
                preferBelow: false,
              ),
            ),
          ] else
            _menuActionsRowBuilder(context),
        ],
      ],
    );
  }

  void _handleResultFromHeroPage(
    BuildContext context,
    dynamic result,
  ) {
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
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        width: 326,
        height: 360,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: LinagoraRefColors.material().primary[100],
          borderRadius: BorderRadius.circular(
            24,
          ),
        ),
        child: EmojiPicker(
          emojiData: emojiData,
          recentEmoji: widget.recentEmojiFuture,
          configuration: EmojiPickerConfiguration(
            emojiStyle: Theme.of(context).textTheme.headlineLarge!,
            searchEmptyTextStyle:
                Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: LinagoraRefColors.material().tertiary[30],
                    ),
            searchEmptyWidget: SvgPicture.asset(
              ImagePaths.icSearchEmojiEmpty,
            ),
            searchFocusNode: FocusNode(),
            showRecentTab: true,
          ),
          itemBuilder: (
            context,
            emojiId,
            emoji,
            callback,
          ) {
            return MouseRegion(
              onHover: (_) {},
              child: EmojiItem(
                onTap: () {
                  callback(emojiId, emoji);
                },
                emoji: emoji,
                textStyle: Theme.of(context).textTheme.headlineLarge!,
              ),
            );
          },
          onEmojiSelected: (
            emojiId,
            emoji,
          ) =>
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
    required bool noBubble,
    required bool displayTime,
    EdgeInsets? paddingBubble,
    bool enableBorder = true,
    MainAxisSize mainAxisSize = MainAxisSize.max,
  }) {
    return Stack(
      key: key,
      alignment: widget.event.isOwnMessage
          ? AlignmentDirectional.bottomStart
          : AlignmentDirectional.bottomEnd,
      children: [
        SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: mainAxisSize,
            children: [
              Container(
                decoration: widget.event.isDisplayOnlyEmoji()
                    ? null
                    : BoxDecoration(
                        borderRadius: MessageStyle.bubbleBorderRadius,
                        color: widget.event.isOwnMessage
                            ? LinagoraRefColors.material().primary[95]
                            : MessageContentWithTimestampBuilder.responsiveUtils
                                    .isMobile(context)
                                ? LinagoraSysColors.material().onPrimary
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                        border: enableBorder
                            ? (!widget.event.isOwnMessage &&
                                    MessageContentWithTimestampBuilder
                                        .responsiveUtils
                                        .isMobile(context)
                                ? Border.all(
                                    color:
                                        MessageStyle.borderColorReceivedBubble,
                                  )
                                : null)
                            : null,
                      ),
                padding: paddingBubble ??
                    (noBubble
                        ? const EdgeInsets.symmetric(
                            horizontal: 16.0,
                          )
                        : MessageStyle.paddingMessageContentBuilder(
                            widget.event,
                          )),
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
                      widget.event.hideDisplayName(
                        widget.nextEvent,
                        MessageContentWithTimestampBuilder.responsiveUtils
                            .isMobile(context),
                      )
                          ? const SizedBox()
                          : DisplayNameWidget(
                              event: widget.event,
                            ),
                      IntrinsicHeight(
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            MessageContentBuilder(
                              event: widget.event,
                              timeline: widget.timeline,
                              availableBubbleContraints:
                                  availableBubbleContraints,
                              onSelect: widget.onSelect,
                              nextEvent: widget.nextEvent,
                              scrollToEventId: widget.scrollToEventId,
                              selectMode: widget.selectMode,
                            ),
                            if (timelineText)
                              Positioned(
                                child: SelectionContainer.disabled(
                                  child: Padding(
                                    padding: MessageStyle.paddingMessageTime,
                                    child: Text.rich(
                                      WidgetSpan(
                                        child: MessageTime(
                                          timelineOverlayMessage: widget
                                              .event.timelineOverlayMessage,
                                          room: widget.event.room,
                                          event: widget.event,
                                          ownMessage: widget.event.isOwnMessage,
                                          timeline: widget.timeline,
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
              if (widget.event.hasAggregatedEvents(
                widget.timeline,
                RelationshipTypes.reaction,
              ))
                const SizedBox(height: 24),
            ],
          ),
        ),
        if (widget.event.hasAggregatedEvents(
          widget.timeline,
          RelationshipTypes.reaction,
        )) ...[
          Positioned(
            left: 8,
            right: 0,
            bottom: 0,
            child: MessageReactions(widget.event, widget.timeline),
          ),
          const SizedBox(width: 4),
        ],
      ],
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
      widget.onSendEmojiReaction?.call(
        emoji,
        event,
      );
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

  Widget _menuActionsRowBuilder(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.isHoverNotifier,
      builder: (context, isHover, child) {
        if (isHover != null && isHover.contains(widget.event.eventId)) {
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
          children: widget.listHorizontalActionMenu.map((item) {
            return Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
              child: TwakeIconButton(
                onTapDown: (tapDownDetails) => widget.onMenuAction?.call(
                  context,
                  item.action,
                  widget.event,
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

  Color? _textContextMenuColor(MessageContextMenuAction action) {
    return action == MessageContextMenuAction.delete
        ? LinagoraSysColors.material().error
        : LinagoraRefColors.material().neutral[30];
  }

  PullDownMenuItemTheme _themeContextMenu(MessageContextMenuAction action) {
    return PullDownMenuItemTheme(
      textStyle: context.textTheme.bodyLarge!.copyWith(
        color: _textContextMenuColor(
          action,
        ),
      ),
    );
  }

  Widget? _iconContextMenu(Event event, MessageContextMenuAction item) {
    return item.imagePath(event) != null
        ? SvgPicture.asset(
            item.imagePath(
                  event,
                ) ??
                '',
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

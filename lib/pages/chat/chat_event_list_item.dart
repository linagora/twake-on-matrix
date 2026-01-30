import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/events/message/message.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/filtered_timeline_extension.dart';
import 'package:fluffychat/widgets/context_menu/context_menu_action.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class ChatEventListItem extends StatelessWidget {
  const ChatEventListItem({
    super.key,
    required this.controller,
    required this.event,
    required this.index,
    required this.constraints,
    this.previousEvent,
    this.nextEvent,
  });

  final ChatController controller;
  final Event event;
  final int index;
  final BoxConstraints constraints;
  final Event? previousEvent;
  final Event? nextEvent;

  @override
  Widget build(BuildContext context) {
    if (!event.isVisibleInGui) return const SizedBox();

    return AutoScrollTag(
      key: ValueKey(event.eventId),
      index: index,
      controller: controller.scrollController,
      highlightColor: Theme.of(context).highlightColor,
      child: Message(
        key: GlobalObjectKey(event.eventId),
        event,
        matrixState: controller.matrix!,
        onSwipe: (direction) => controller.replyAction(replyTo: event),
        onAvatarTap: (Event event) => controller.onContactTap(
          contactPresentationSearch:
              event.senderFromMemoryOrFallback.toContactPresentationSearch(),
          context: context,
          path: 'rooms',
        ),
        onSelect: controller.onSelectMessage,
        selectMode: controller.selectMode,
        maxWidth: constraints.maxWidth,
        scrollToEventId: (String eventId) => controller.scrollToEventId(
          eventId,
          highlight: true,
        ),
        selected:
            controller.selectedEvents.any((e) => e.eventId == event.eventId),
        timeline: controller.timeline!,
        previousEvent: previousEvent,
        nextEvent: nextEvent,
        onHover: (isHover, event) => controller.onHover(isHover, index, event),
        isHoverNotifier: controller.focusHover,
        listHorizontalActionMenu:
            controller.listHorizontalActionMenuBuilder(event),
        onMenuAction: controller.handleHorizontalActionMenu,
        hideKeyboardChatScreen: controller.onHideKeyboardAndEmoji,
        markedUnreadLocation: controller.unreadReceivedMessageLocation,
        timestampCallback: (event) {
          controller.handleDisplayStickyTimestamp(
            event.originServerTs,
          );
        },
        onEventVisible: controller.onEventVisible,
        onDisplayEmojiReaction: controller.onDisplayEmojiReaction,
        onHideEmojiReaction: controller.onHideEmojiReaction,
        listAction:
            controller.listHorizontalActionMenuBuilder(event).map((action) {
          return ContextMenuAction(
            name: action.action.name,
          );
        }).toList(),
        onPickEmojiReaction: () {},
        onSelectEmojiReaction: (emoji, event) {
          controller.sendEmojiAction(
            emoji: emoji,
            event: event,
          );
        },
        onForward: (event) {
          controller.forwardEventsAction(event: event);
        },
        onReply: (event) {
          controller.replyAction(replyTo: event);
        },
        onCopy: controller.copyEventsAction,
        onPin: (event) {
          controller.pinEventAction(event);
        },
        onSaveToDownload: (event) =>
            controller.saveSelectedEventToDownloadAndroid(
          context,
          event,
        ),
        onSaveToGallery: (event) =>
            controller.saveSelectedEventToGallery(context, event),
        onTapMoreButton: controller.handleOnTapMoreButtonOnWeb,
        onEdit: (event) {
          controller.editAction(editEvent: event);
        },
        onDelete: (context, event) {
          controller.deleteEventAction(context, event);
        },
        recentEmojiFuture: controller.getRecentReactionsInteractor.execute(),
        onReport: controller.reportEventAction,
        onRetryTextMessage: controller.retryTextMessage,
      ),
    );
  }
}

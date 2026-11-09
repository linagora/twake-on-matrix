import 'package:twake_chat/pages/chat/chat.dart';
import 'package:twake_chat/utils/media_album/media_album_scope.dart';
import 'package:twake_chat/pages/chat/events/message/message.dart';
import 'package:twake_chat/presentation/model/search/presentation_search.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/filtered_timeline_extension.dart';
import 'package:twake_chat/widgets/context_menu/context_menu_action.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class ChatEventListItem extends StatelessWidget {
  const ChatEventListItem({
    super.key,
    required this.controller,
    required this.event,
    required this.index,
    required this.constraints,
    this.previousEvent,
    this.nextEvent,
    this.albumMembers,
    this.hiddenAlbumMember = false,
  });

  final ChatController controller;
  final Event event;
  final int index;
  final BoxConstraints constraints;
  final Event? previousEvent;
  final Event? nextEvent;

  /// Set on the leader of an album (oldest first); the other members pass
  /// [hiddenAlbumMember]. Both are ignored in select mode so that every
  /// image can be selected on its own.
  final List<Event>? albumMembers;
  final bool hiddenAlbumMember;

  @override
  Widget build(BuildContext context) {
    if (!event.isVisibleInGui) return const SizedBox();
    if (hiddenAlbumMember && !controller.selectMode) {
      return SizedBox(key: GlobalObjectKey(event.eventId));
    }
    final message = _buildMessage(context);
    final members = albumMembers;
    if (members == null || controller.selectMode) return message;
    return MediaAlbumScope(members: members, child: message);
  }

  Widget _buildMessage(BuildContext context) {
    return Message(
      key: GlobalObjectKey(event.eventId),
      event,
      autoScrollController: controller.scrollController,
      scrollIndex: index,
      matrixState: controller.matrix!,
      onSwipe: (direction) => controller.replyAction(replyTo: event),
      onAvatarTap: (Event event) => controller.onContactTap(
        contactPresentationSearch: event.senderFromMemoryOrFallback
            .toContactPresentationSearch(),
        context: context,
        path: 'rooms',
      ),
      onSelect: controller.onSelectMessage,
      selectMode: controller.selectMode,
      maxWidth: constraints.maxWidth,
      scrollToEventId: (String eventId) =>
          controller.scrollToEventId(eventId, highlight: true),
      selected: controller.selectedEvents.any(
        (e) => e.eventId == event.eventId,
      ),
      timeline: controller.timeline!,
      previousEvent: previousEvent,
      nextEvent: nextEvent,
      onHover: (isHover, event) => controller.onHover(isHover, event),
      isHoverNotifier: controller.focusHover,
      highlightedEventIdNotifier: controller.highlightedEventIdNotifier,
      listHorizontalActionMenu: controller.listHorizontalActionMenuBuilder(
        event,
      ),
      onMenuAction: controller.handleHorizontalActionMenu,
      hideKeyboardChatScreen: controller.onHideKeyboardAndEmoji,
      markedUnreadLocation: controller.unreadReceivedMessageLocation,
      timestampCallback: (event) {
        controller.handleDisplayStickyTimestamp(event.originServerTs);
      },
      onEventVisible: controller.onEventVisible,
      onDisplayEmojiReaction: controller.onDisplayEmojiReaction,
      onHideEmojiReaction: controller.onHideEmojiReaction,
      listAction: controller.listHorizontalActionMenuBuilder(event).map((
        action,
      ) {
        return ContextMenuAction(name: action.action.name);
      }).toList(),
      onPickEmojiReaction: () {},
      onToggleEmojiReaction: (emoji, event) =>
          controller.toggleReactionAction(emoji: emoji, event: event),
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
          controller.saveSelectedEventToDownloadAndroid(context, event),
      onSaveToGallery: (event) =>
          controller.saveSelectedEventToGallery(context, event),
      onTapMoreButton: controller.handleOnTapMoreButtonOnWeb,
      onEdit: (event) {
        controller.editAction(editEvent: event);
      },
      onDelete: (context, event) {
        controller.deleteEventAction(context, event);
      },
      recentEmojiFuture: controller.getRecentEmoji(),
      onReport: controller.reportEventAction,
      onRetryTextMessage: controller.retryTextMessage,
    );
  }
}

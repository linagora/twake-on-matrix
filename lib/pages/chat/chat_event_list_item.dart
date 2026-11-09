import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/domain/model/thread/thread_rules.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/domain/model/thread/thread_summary.dart';
import 'package:twake_chat/pages/chat/chat.dart';
import 'package:twake_chat/pages/chat/thread/thread_summary_card.dart';
import 'package:twake_chat/pages/chat/events/message/message.dart';
import 'package:twake_chat/presentation/model/search/presentation_search.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/matrix_locals.dart';
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
  });

  final ChatController controller;
  final Event event;
  final int index;
  final BoxConstraints constraints;
  final Event? previousEvent;
  final Event? nextEvent;

  @override
  Widget build(BuildContext context) {
    if (!controller.isEventVisible(event)) return const SizedBox();

    final threadSummary = controller.threadSummaryOf(event);
    final canStartThread = ThreadRules.canStartThread(
      event,
      hasThread: threadSummary != null,
      inThreadScreen: controller.isThread,
    );

    return Message(
      // The room's Chat stays mounted under the thread screen and can show
      // the same event: a second GlobalObjectKey for it would throw.
      key: controller.isThread
          ? ValueKey(event.eventId)
          : GlobalObjectKey(event.eventId),
      event,
      autoScrollController: controller.scrollController,
      scrollIndex: index,
      matrixState: controller.matrix!,
      inThread: controller.isThread,
      threadCard: threadSummary == null
          ? null
          : _threadCard(context, threadSummary),
      onStartThread: canStartThread
          ? (event) => _openThread(context, start: true)
          : null,
      // No reply to quote in a thread: replyAction does nothing there.
      onSwipe: controller.isThread
          ? null
          : (direction) => controller.replyAction(replyTo: event),
      onAvatarTap: (Event event) => controller.onContactTap(
        contactPresentationSearch: event.senderFromMemoryOrFallback
            .toContactPresentationSearch(),
        context: context,
        path: 'rooms',
      ),
      onSelect: controller.onSelectMessage,
      selectMode: controller.selectMode,
      maxWidth: constraints.maxWidth,
      // The thread list has no GlobalObjectKey rows: scroll by index there.
      scrollToEventId: (String eventId) => controller.isThread
          ? controller.scrollToThreadEvent(eventId)
          : controller.scrollToEventId(eventId, highlight: true),
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

  void _openThread(BuildContext context, {bool start = false}) => ThreadRoute(
    roomid: event.room.id,
    rootid: event.eventId,
    start: start,
  ).push<void>(context);

  /// The edited body of a text reply, else the localized label of the
  /// reply (a file, a voice message, an undecryptable event).
  String? _lastReplyText(BuildContext context, ThreadSummary summary) {
    final reply = summary.lastReply;
    if (reply == null) return null;
    if (reply.type == EventTypes.Message &&
        reply.messageType == MessageTypes.Text) {
      return summary.lastReplyText;
    }
    return reply.calcLocalizedBodyFallback(
      MatrixLocals(L10n.of(context)!),
      withSenderNamePrefix: false,
      hideReply: true,
    );
  }

  Widget _threadCard(BuildContext context, ThreadSummary summary) =>
      ListenableBuilder(
        listenable: controller.threadUnreadStore ?? Listenable.merge(const []),
        builder: (context, _) => ThreadSummaryCard(
          replyCount: summary.replyCount,
          lastReplyAuthor: summary.lastReply?.senderFromMemoryOrFallback
              .calcDisplayname(),
          lastReplyText: _lastReplyText(context, summary),
          lastReplyTime: summary.lastReply?.originServerTs,
          unreadCount: controller.threadUnreadCount(event.eventId),
          onOwnBubble: event.isOwnMessage,
          onTap: () => _openThread(context),
        ),
      );
}

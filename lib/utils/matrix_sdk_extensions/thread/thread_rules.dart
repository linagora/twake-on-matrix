import 'package:collection/collection.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/thread/thread_relation_extension.dart';

abstract final class ThreadRules {
  static bool canStartThread(
    Event event, {
    required bool hasThread,
    bool inThreadScreen = false,
  }) =>
      AppConfig.threadsEnabled &&
      !hasThread &&
      !inThreadScreen &&
      event.room.canSendDefaultMessages &&
      event.type == EventTypes.Message &&
      event.status.isSynced &&
      event.threadRootId == null;

  /// The `?event=` a screen jumps to. go_router gives every route of the
  /// stack the full URI: under a thread route (`/rooms/R/threads/T`) the room
  /// screen must ignore the thread's reply, which is not in its timeline.
  static String? highlightEventIdFromUri(Uri uri, {required bool isThread}) {
    final segments = uri.pathSegments;
    final onThreadRoute = segments.length > 3 && segments[2] == 'threads';
    if (onThreadRoute && !isThread) return null;
    final event = uri.queryParameters['event'];
    return event == null || event.isEmpty ? null : event;
  }

  /// The event every main-timeline receipt targets: Synapse refuses a `main`
  /// receipt on a thread event or an event related to one (edit, reaction).
  /// A reply deleted since lost its `m.relates_to`: [knownThreadReplyIds]
  /// (the replies seen in a thread) tell it apart.
  static Event? newestMainTimelineEvent(
    Iterable<Event> eventsNewestFirst, {
    Set<String> knownThreadReplyIds = const {},
  }) => eventsNewestFirst.firstWhereOrNull(
    (e) =>
        e.status.isSynced &&
        e.threadRootId == null &&
        !knownThreadReplyIds.contains(e.eventId) &&
        e.type != EventTypes.Redaction &&
        e.relationshipType != RelationshipTypes.edit &&
        e.relationshipType != RelationshipTypes.reaction,
  );

  /// The "quote reply" action: a thread has no quote reply, and the member
  /// must be allowed to send messages.
  static bool canQuoteReply(Event event, {required bool inThreadScreen}) =>
      !inThreadScreen && event.room.canSendDefaultMessages;

  /// The event the "unread messages" separator sits above: the oldest
  /// unread message the room shows. [eventsNewestFirst] as the timeline
  /// gives them; null when the read marker is not loaded or nothing visible
  /// is unread. A thread reply is hidden in the room: it gets no separator.
  static String? unreadSeparatorEventId(
    List<Event> eventsNewestFirst, {
    required String fullyReadEventId,
    required String? ownUserId,
    required bool Function(Event event) isVisible,
  }) {
    final readIndex = eventsNewestFirst.indexWhere(
      (e) => e.eventId == fullyReadEventId,
    );
    if (readIndex <= 0) return null;
    return eventsNewestFirst
        .getRange(0, readIndex)
        .lastWhereOrNull((e) => e.senderId != ownUserId && isVisible(e))
        ?.eventId;
  }
}

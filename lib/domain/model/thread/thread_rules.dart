import 'package:collection/collection.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/model/room/room_extension.dart';
import 'package:twake_chat/domain/model/thread/thread_relation_extension.dart';

abstract final class ThreadRules {
  static bool canStartThread(
    Event event, {
    required bool hasThread,
    bool inThreadScreen = false,
  }) =>
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
  static Event? newestMainTimelineEvent(Iterable<Event> eventsNewestFirst) =>
      eventsNewestFirst.firstWhereOrNull(
        (e) =>
            e.status.isSynced &&
            e.threadRootId == null &&
            e.type != EventTypes.Redaction &&
            e.relationshipType != RelationshipTypes.edit &&
            e.relationshipType != RelationshipTypes.reaction,
      );

  /// Whether a main-timeline message raises a local notification: the room
  /// counters, which the push rules fill (the ones without threads). A muted
  /// room: mention only.
  static bool shouldNotifyMainTimelineEvent(Room room) =>
      room.notificationCount > 0 && (!room.isMuted || room.highlightCount > 0);

  /// Whether a thread reply raises a local notification. The push rules
  /// ([pushActions], `client.pushruleEvaluator.match(event)`) decide first,
  /// then the thread filter: followed, or highlighted. The room counters
  /// leave thread messages out and the thread counters land after the event.
  static bool shouldNotifyThreadEvent(
    Event event, {
    required bool followed,
    required EvaluatedPushRuleAction pushActions,
    String? rootSenderId,
    ({String roomId, String threadRootId})? activeThread,
  }) {
    final me = event.room.client.userID;
    if (event.senderId == me) return false;
    if (_readByOwnReceipt(event)) return false;
    if (activeThread != null &&
        activeThread.roomId == event.room.id &&
        activeThread.threadRootId == event.threadRootId) {
      return false;
    }
    if (!pushActions.notify) return false;
    return followed || rootSenderId == me || pushActions.highlight;
  }

  /// MSC3771: only the receipt of the thread or an unthreaded one reads a
  /// thread reply; a `main` receipt covers the main timeline only.
  static bool _readByOwnReceipt(Event event) {
    final receipts = event.room.receiptState;
    final readAt = [
      receipts.global.latestOwnReceipt?.ts,
      receipts.byThread[event.threadRootId]?.latestOwnReceipt?.ts,
    ].nonNulls;
    return readAt.any(
      (ts) => event.originServerTs.millisecondsSinceEpoch <= ts,
    );
  }
}

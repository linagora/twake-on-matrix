import 'package:collection/collection.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/model/room/room_extension.dart';
import 'package:twake_chat/domain/model/thread/thread_relation_extension.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/event_extension.dart';

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

  /// Whether a thread reply raises a local notification. Decided from the
  /// reply and the follow state: the room counters leave thread messages out
  /// and the thread counters land after the event. A muted room: mention only.
  static bool shouldNotifyThreadEvent(
    Event event, {
    required bool followed,
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
    if (event.room.isMuted) return event.isMention;
    return followed || rootSenderId == me || event.isMention;
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

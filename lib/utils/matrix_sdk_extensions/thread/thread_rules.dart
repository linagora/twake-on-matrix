import 'dart:async';

import 'package:collection/collection.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/domain/model/room/room_extension.dart';
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

  /// [shouldNotifyThreadEvent] for a reply, with what it needs found only
  /// when nothing else decided: the filters (own message, read, thread on
  /// screen, push rules) and a mention come first, without waiting. Then
  /// [followed] (may still be looked up), then the sender of the root, which
  /// a lookup that told nothing leaves as the last word. A root that cannot
  /// be loaded counts as unknown; nothing is thrown.
  static Future<bool> shouldNotifyThreadReply(
    Event event, {
    required FutureOr<bool?> followed,
    required EvaluatedPushRuleAction pushActions,
    ({String roomId, String threadRootId})? activeThread,
  }) async {
    bool decide(bool isFollowed, String? rootSenderId) =>
        shouldNotifyThreadEvent(
          event,
          followed: isFollowed,
          pushActions: pushActions,
          rootSenderId: rootSenderId,
          activeThread: activeThread,
        );
    if (!decide(true, null)) return false;
    if (decide(false, null)) return true;
    if (await _followOrNull(followed) == true) return true;
    return decide(false, await _rootSenderOrNull(event));
  }

  static Future<bool?> _followOrNull(FutureOr<bool?> followed) async {
    try {
      return await followed;
    } catch (e, s) {
      Logs().w('Unable to tell if the thread is followed', e, s);
      return null;
    }
  }

  static Future<String?> _rootSenderOrNull(Event event) async {
    final rootId = event.threadRootId;
    if (rootId == null) return null;
    try {
      return (await event.room.getEventById(rootId))?.senderId;
    } catch (e, s) {
      Logs().w('Unable to load the root of the thread', e, s);
      return null;
    }
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

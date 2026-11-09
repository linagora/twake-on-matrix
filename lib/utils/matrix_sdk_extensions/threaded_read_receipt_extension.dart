import 'dart:math' as math;

import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/domain/model/thread/thread_relation_extension.dart';
import 'package:twake_chat/domain/model/thread/thread_rules.dart';
import 'package:twake_chat/utils/thread_unread/thread_unread_store.dart';

/// Read receipts carrying a `thread_id`: `main` for the room timeline, the
/// root id for a thread. The SDK's `Room.setReadMarker` sends unthreaded
/// receipts, which the server applies to every thread of the room.
extension ThreadedReadReceiptExtension on Room {
  static const String mainThreadId = 'main';

  /// Reads the main timeline up to [event]; `m.fully_read` follows it.
  Future<void> setMainTimelineReadMarker(Event event) async {
    await _postReceipt(event);
    await client.setReadMarker(id, mFullyRead: event.eventId);
  }

  /// Reads the [thread] up to [event]; `m.fully_read` stays.
  Future<void> setThreadReadMarker(Event event, ThreadRef thread) =>
      _postReceipt(event, thread: thread);

  /// "Mark as read" on a room: its main timeline and every given thread.
  Future<void> markRoomAndThreadsRead({
    required Event mainEvent,
    required Map<ThreadRef, Event> lastReplyByThread,
  }) async {
    await setMainTimelineReadMarker(mainEvent);
    for (final entry in lastReplyByThread.entries) {
      await setThreadReadMarker(entry.value, entry.key);
    }
  }

  /// SDK `hasNewMessages` reads `receiptState.global` only, which the app
  /// never moves (it sends threaded receipts). The own read position is the
  /// newest own receipt: unthreaded, main, or the thread of the last event.
  /// A thread reply as last event must not hide an unread main message: the
  /// room is also unread when its newest main message (seen live) is newer
  /// than the main or unthreaded receipt.
  bool get hasNewMessagesWithThreads {
    final last = lastEvent;
    if (last == null || !client.roomPreviewLastEvents.contains(last.type)) {
      return false;
    }
    if (last.senderId == client.userID) return false;
    final rootId = last.threadRootId;
    if (rootId == null) return _isNewerThanRead(last);
    return _hasUnreadWatchedReply(last, ThreadRef(id, rootId)) ||
        _hasUnreadMainMessage;
  }

  /// The user reads the thread in a screen of its own: only a followed or
  /// mentioning thread counts as new messages of the room.
  bool _hasUnreadWatchedReply(Event reply, ThreadRef thread) =>
      _isThreadWatched(thread) && _isNewerThanRead(reply, thread: thread);

  bool _isThreadWatched(ThreadRef thread) {
    final store = client.threadUnread;
    if (store == null) return false;
    if (store.isFollowed(thread)) return true;
    return store
        .threadsOf(this)
        .any(
          (t) => t.rootEventId == thread.rootEventId && t.highlightCount > 0,
        );
  }

  bool get _hasUnreadMainMessage {
    final newest = client.threadUnread?.newestMainMessageTs(this);
    return newest != null && newest > _ownReadTs();
  }

  bool _isNewerThanRead(Event event, {ThreadRef? thread}) =>
      _ownReadTs(thread: thread) < event.originServerTs.millisecondsSinceEpoch;

  /// Newest own receipt that covers the main timeline, or the thread.
  int _ownReadTs({ThreadRef? thread}) => [
    receiptState.global.latestOwnReceipt?.ts,
    // MSC3771: a `main` receipt covers the main timeline only.
    if (thread == null)
      receiptState.mainThread?.latestOwnReceipt?.ts
    else
      receiptState.byThread[thread.rootEventId]?.latestOwnReceipt?.ts,
  ].nonNulls.fold<int>(0, math.max);

  /// A receipt on the [thread], or on the main timeline when null.
  Future<void> _postReceipt(Event event, {ThreadRef? thread}) =>
      client.postReceipt(
        id,
        client.receiptsPublicByDefault
            ? ReceiptType.mRead
            : ReceiptType.mReadPrivate,
        event.eventId,
        threadId: thread?.rootEventId ?? mainThreadId,
      );
}

extension ThreadedTimelineReadMarkerExtension on Timeline {
  /// Reads the main timeline up to [event], or its last synced event that
  /// is not a thread reply (a main receipt on a thread event is refused).
  Future<void> setMainTimelineReadMarker({Event? event}) async {
    event ??= ThreadRules.newestMainTimelineEvent(
      events,
      knownThreadReplyIds:
          room.client.threadUnread?.knownThreadReplyIds(room) ?? const {},
    );
    if (event == null) return;
    // Already read there: no receipt, no request.
    if (event.eventId ==
        room.receiptState.mainThread?.latestOwnReceipt?.eventId) {
      return;
    }
    return room.setMainTimelineReadMarker(event);
  }
}

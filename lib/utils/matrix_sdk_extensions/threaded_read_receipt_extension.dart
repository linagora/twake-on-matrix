import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/model/thread/thread_relation_extension.dart';
import 'package:twake_chat/domain/model/thread/thread_rules.dart';
import 'package:twake_chat/utils/thread_unread/thread_unread_store.dart';

/// Read receipts carrying a `thread_id`: `main` for the room timeline, the
/// root id for a thread. The SDK's `Room.setReadMarker` sends unthreaded
/// receipts, which the server applies to every thread of the room.
extension ThreadedReadReceiptExtension on Room {
  static const String mainThreadId = 'main';

  /// Reads the main timeline up to [eventId]; `m.fully_read` follows it.
  Future<void> setMainTimelineReadMarker(String eventId) async {
    await _postReceipt(eventId, mainThreadId);
    await client.setReadMarker(id, mFullyRead: eventId);
  }

  /// Reads the thread [threadRootId] up to [eventId]; `m.fully_read` stays.
  Future<void> setThreadReadMarker({
    required String threadRootId,
    required String eventId,
  }) => _postReceipt(eventId, threadRootId);

  /// "Mark as read" on a room: its main timeline and every given thread.
  Future<void> markRoomAndThreadsRead({
    required String mainEventId,
    required Map<String, String> lastEventIdByThreadRootId,
  }) async {
    await setMainTimelineReadMarker(mainEventId);
    for (final entry in lastEventIdByThreadRootId.entries) {
      await setThreadReadMarker(threadRootId: entry.key, eventId: entry.value);
    }
  }

  /// SDK `hasNewMessages` reads `receiptState.global` only, which the app
  /// never moves (it sends threaded receipts). The own read position is the
  /// newest own receipt: unthreaded, main, or the thread of the last event.
  bool get hasNewMessagesWithThreads {
    final last = lastEvent;
    if (last == null || !client.roomPreviewLastEvents.contains(last.type)) {
      return false;
    }
    if (last.senderId == client.userID) return false;
    final rootId = last.threadRootId;
    if (rootId != null) {
      final thread = client.threadUnread
          ?.threadsOf(id)
          .where((t) => t.rootEventId == rootId)
          .firstOrNull;
      if (thread?.followed != true && (thread?.highlightCount ?? 0) == 0) {
        return false;
      }
    }
    final readAt = [
      receiptState.global.latestOwnReceipt?.ts,
      receiptState.mainThread?.latestOwnReceipt?.ts,
      if (rootId != null) receiptState.byThread[rootId]?.latestOwnReceipt?.ts,
    ].nonNulls.fold<int>(0, (a, b) => a > b ? a : b);
    return readAt < last.originServerTs.millisecondsSinceEpoch;
  }

  Future<void> _postReceipt(String eventId, String threadId) =>
      client.postReceipt(
        id,
        client.receiptsPublicByDefault
            ? ReceiptType.mRead
            : ReceiptType.mReadPrivate,
        eventId,
        threadId: threadId,
      );
}

extension ThreadedTimelineReadMarkerExtension on Timeline {
  /// Reads the main timeline up to [eventId], or its last synced event that
  /// is not a thread reply (a main receipt on a thread event is refused).
  Future<void> setMainTimelineReadMarker({String? eventId}) async {
    eventId ??= ThreadRules.newestMainTimelineEvent(events)?.eventId;
    if (eventId == null) return;
    // Already read there: no receipt, no request.
    if (eventId == room.receiptState.mainThread?.latestOwnReceipt?.eventId) {
      return;
    }
    return room.setMainTimelineReadMarker(eventId);
  }
}

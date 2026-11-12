import 'package:matrix/matrix.dart';
import 'package:twake_chat/utils/thread_unread/thread_unread_store.dart';

import '../../domain/usecase/room/send_text_message_interactor_test.mocks.dart';
import '../../fake_client.dart';

/// An event deleted by [sender]: no content left, so no `m.relates_to`.
Event deletedEvent({
  required String eventId,
  required String sender,
  required Room room,
  required DateTime sentAt,
}) => Event(
  type: EventTypes.Message,
  content: const {},
  eventId: eventId,
  senderId: sender,
  originServerTs: sentAt,
  unsigned: {
    'redacted_because': {
      'type': EventTypes.Redaction,
      'event_id': '${eventId}_redaction',
      'sender': sender,
      'origin_server_ts': sentAt
          .add(const Duration(minutes: 1))
          .millisecondsSinceEpoch,
      'content': const {},
      'redacts': eventId,
    },
  },
  room: room,
);

/// Stored events of a room, newest first, paged like the SDK database.
class StoredEvents extends MockDatabase {
  StoredEvents(this.events);

  final List<Event> events;

  @override
  Future<List<Event>> getEventList(
    Room room, {
    int start = 0,
    bool onlySending = false,
    int? limit,
  }) async {
    final stored = events
        .where((e) => !onlySending || e.status.isSending)
        .skip(start);
    return (limit == null ? stored : stored.take(limit)).toList();
  }
}

/// A read receipt that reached the server: through `POST /receipt`, or as
/// `m.read` / `m.read.private` of `POST /read_markers` (unthreaded).
typedef SentReceipt = ({String eventId, String? threadId, bool public});

/// A client that keeps the thread counters, like [TwakeClient], and records
/// the read receipts and the `m.fully_read` markers it sends, whichever
/// request carries them. The calls still reach the mock: `verify` works.
class RecordingThreadClient extends MockClient
    implements ThreadUnreadStoreOwner {
  @override
  late final ThreadUnreadStore threadUnread = ThreadUnreadStore(client: this);

  final List<SentReceipt> receipts = [];
  final List<String> fullyRead = [];

  // Nullable as the mock's: `verify(... any ...)` calls it with nulls.
  @override
  Future<void> postReceipt(
    String? roomId,
    ReceiptType? receiptType,
    String? eventId, {
    String? threadId,
  }) {
    if (eventId != null) {
      receipts.add((
        eventId: eventId,
        threadId: threadId,
        public: receiptType == ReceiptType.mRead,
      ));
    }
    return super.postReceipt(roomId, receiptType, eventId, threadId: threadId);
  }

  @override
  Future<void> setReadMarker(
    String? roomId, {
    String? mFullyRead,
    String? mRead,
    String? mReadPrivate,
  }) {
    if (mFullyRead != null) fullyRead.add(mFullyRead);
    final receipt = mRead ?? mReadPrivate;
    if (receipt != null) {
      receipts.add((eventId: receipt, threadId: null, public: mRead != null));
    }
    return super.setReadMarker(
      roomId,
      mFullyRead: mFullyRead,
      mRead: mRead,
      mReadPrivate: mReadPrivate,
    );
  }
}

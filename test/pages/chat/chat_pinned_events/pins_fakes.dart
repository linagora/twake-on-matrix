// ignore_for_file: implementation_imports

import 'package:matrix/matrix.dart';
import 'package:matrix/src/models/timeline_chunk.dart';

import '../../../fake_client.dart';

const pinsRoomId = '!pins:example.org';
const pinsRootId = r'$root:example.org';
const pinsReplyId = r'$reply:example.org';
const pinsOtherRootId = r'$other-root:example.org';
const pinsOtherReplyId = r'$other-reply:example.org';
const pinsRoomMessageId = r'$room-message:example.org';

/// A room whose pinned ids and events are set by the test: the pinned bar
/// reads `m.room.pinned_events` and loads each pin by id.
class PinsRoom extends Room {
  PinsRoom(Client client) : super(id: pinsRoomId, client: client);

  final Map<String, Event> _events = {};

  /// The content of `m.room.pinned_events`, in the order the state holds it.
  List<String> pinned = [];

  @override
  List<String> get pinnedEventIds => List.of(pinned);

  @override
  Future<Event?> getEventById(String eventID) async => _events[eventID];

  /// The new `m.room.pinned_events`, as the server would store it.
  @override
  Future<String> setPinnedEvents(List<String> pinnedEventIds) async {
    pinned = List.of(pinnedEventIds);
    return r'$pinned-state:example.org';
  }

  /// The first load of the pins opens a timeline; an empty one will do.
  @override
  Future<Timeline> getTimeline({
    void Function(int index)? onChange,
    void Function(int index)? onRemove,
    void Function(int insertID)? onInsert,
    void Function()? onNewEvent,
    void Function()? onUpdate,
    String? eventContextId,
    int? limit = Room.defaultHistoryCount,
  }) async => Timeline(
    room: this,
    chunk: TimelineChunk(events: []),
  );

  /// A text message of this room, sent [minute] minutes after 10:00; a
  /// reply of the thread [threadRootId] when given, with the relation the
  /// web and the SDK write.
  Event message(
    String eventId,
    String body, {
    required int minute,
    String? threadRootId,
  }) {
    final event = Event(
      content: {
        'msgtype': MessageTypes.Text,
        'body': body,
        if (threadRootId != null)
          'm.relates_to': {
            'rel_type': RelationshipTypes.thread,
            'event_id': threadRootId,
            'is_falling_back': true,
            'm.in_reply_to': {'event_id': threadRootId},
          },
      },
      type: EventTypes.Message,
      eventId: eventId,
      senderId: '@bob:example.org',
      originServerTs: DateTime.utc(2026, 11, 12, 10, minute),
      room: this,
    );
    _events[eventId] = event;
    return event;
  }
}

class PinsClient extends Client {
  PinsClient()
    : super('pins-test', httpClient: FakeMatrixApi(), database: MockDatabase());

  PinsRoom? room;

  @override
  String? get userID => '@alice:example.org';

  @override
  Room? getRoomById(String id) => room?.id == id ? room : null;
}

/// A room with: a thread (root + one reply), the reply of another thread,
/// and a plain message of the room. Nothing is pinned yet.
({PinsClient client, PinsRoom room}) roomWithThreads() {
  final client = PinsClient();
  final room = PinsRoom(client);
  client.room = room;
  room
    ..message(pinsRootId, 'the root', minute: 1)
    ..message(pinsReplyId, 'the reply', minute: 2, threadRootId: pinsRootId)
    ..message(pinsOtherRootId, 'another root', minute: 3)
    ..message(
      pinsOtherReplyId,
      'a reply elsewhere',
      minute: 4,
      threadRootId: pinsOtherRootId,
    )
    ..message(pinsRoomMessageId, 'a room message', minute: 5);
  return (client: client, room: room);
}

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/utils/notification_location.dart';

import '../domain/usecase/room/send_text_message_interactor_test.mocks.dart';

/// Review 4515438122 (jbrnzl), THR-M-11: tapping the notification of a
/// thread reply opens the thread screen on that reply, with its room
/// beneath, like a thread reply opened from the search. A message of the
/// main timeline opens the room on it. The ids go through the typed routes,
/// so an event id of a v3 room (`+`, `/`) survives the query string.
void main() {
  setUp(() {
    _client = MockClient();
    _room = MockRoom();
    when(_room.id).thenReturn(_roomId);
    when(_room.client).thenReturn(_client);
    when(_client.getRoomById(_roomId)).thenReturn(_room);
  });

  group('the location of a notification', _locationTests);

  /// What the tap knows is the room and the event id of the push: the event
  /// tells whether it is a thread reply. When it cannot be loaded, the tap
  /// still opens the room on the event, as before threads.
  group('the location of a tapped notification', _resolveTests);
}

const _roomId = '!room:example.com';
const _rootId = r'$root';
const _replyId = r'$reply';

/// An event id of a v3 room: base64 with `+` and `/`.
const _v3ReplyId = r'$ab+cd/ef';

late MockClient _client;
late MockRoom _room;

String _threadLocation(String eventId) =>
    ThreadRoute(roomid: _roomId, rootid: _rootId, event: eventId).location;

String _roomLocation(String eventId) =>
    RoomRoute(roomid: _roomId, event: eventId).location;

Event _event({required String eventId, String? threadRootId}) => Event(
  type: EventTypes.Message,
  content: {
    'msgtype': 'm.text',
    'body': 'hello',
    if (threadRootId != null)
      'm.relates_to': {
        'rel_type': RelationshipTypes.thread,
        'event_id': threadRootId,
        'is_falling_back': true,
      },
  },
  eventId: eventId,
  senderId: '@bob:example.com',
  originServerTs: DateTime.utc(2026, 11, 9),
  room: _room,
);

void _locationTests() {
  test('a thread reply opens its thread on the reply', () {
    expect(
      notificationLocation(
        roomId: _roomId,
        eventId: _replyId,
        threadRootId: _rootId,
      ),
      _threadLocation(_replyId),
    );
  });

  test('a message of the room opens the room on it', () {
    expect(
      notificationLocation(roomId: _roomId, eventId: _replyId),
      _roomLocation(_replyId),
    );
  });

  test('a notification without event opens the room', () {
    expect(
      notificationLocation(roomId: _roomId),
      const RoomRoute(roomid: _roomId).location,
    );
  });

  test('a v3 event id of a thread reply keeps its + and /', () {
    final location = notificationLocation(
      roomId: _roomId,
      eventId: _v3ReplyId,
      threadRootId: _rootId,
    );

    expect(Uri.parse(location).queryParameters['event'], _v3ReplyId);
  });

  test('a v3 event id of a room message keeps its + and /', () {
    final location = notificationLocation(roomId: _roomId, eventId: _v3ReplyId);

    expect(Uri.parse(location).queryParameters['event'], _v3ReplyId);
  });
}

Future<String> _tapped({String? eventId = _replyId}) =>
    resolveNotificationLocation(_client, _roomId, eventId: eventId);

void _resolveTests() {
  test('a thread reply opens its thread on the reply', () async {
    when(
      _room.getEventById(_replyId),
    ).thenAnswer((_) async => _event(eventId: _replyId, threadRootId: _rootId));

    expect(await _tapped(), _threadLocation(_replyId));
  });

  test('a message of the room opens the room on it', () async {
    when(
      _room.getEventById(_replyId),
    ).thenAnswer((_) async => _event(eventId: _replyId));

    expect(await _tapped(), _roomLocation(_replyId));
  });

  test('the root of a thread opens the room on it', () async {
    when(
      _room.getEventById(_rootId),
    ).thenAnswer((_) async => _event(eventId: _rootId));

    expect(await _tapped(eventId: _rootId), _roomLocation(_rootId));
  });

  test('an event the server cannot give opens the room on it', () async {
    when(_room.getEventById(_replyId)).thenAnswer(
      (_) async => throw MatrixException.fromJson({'errcode': 'M_UNKNOWN'}),
    );

    expect(await _tapped(), _roomLocation(_replyId));
  });

  test('an event that is not found opens the room on it', () async {
    when(_room.getEventById(_replyId)).thenAnswer((_) async => null);

    expect(await _tapped(), _roomLocation(_replyId));
  });

  test('a room the account does not know yet opens the room', () async {
    when(_client.getRoomById(_roomId)).thenReturn(null);

    expect(await _tapped(), _roomLocation(_replyId));
  });

  test('a notification without event opens the room without loading '
      'anything', () async {
    expect(
      await _tapped(eventId: null),
      const RoomRoute(roomid: _roomId).location,
    );
    verifyNever(_room.getEventById(any));
  });
}

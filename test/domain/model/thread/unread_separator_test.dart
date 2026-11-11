import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/matrix_events/event_visibility_resolver.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/thread/thread_rules.dart';

import '../room/room_extension_test.mocks.dart';

/// CodeRabbit 4515288024: the "unread messages" separator of the room sits
/// above the oldest unread message the room shows. A thread reply is hidden
/// in the room (THR-M-01): when it is the oldest unread event, the separator
/// goes to the next visible message, else it sits on a row never built and
/// disappears.
void main() {
  late MockRoom room;

  const me = '@me:example.com';
  const bob = '@bob:example.com';
  const fullyRead = r'$fully_read';

  setUp(() {
    room = MockRoom();
    when(room.id).thenReturn('!room:example.com');
  });

  Event event(String eventId, {String sender = bob, bool inThread = false}) =>
      Event(
        type: EventTypes.Message,
        content: {
          'msgtype': 'm.text',
          'body': eventId,
          if (inThread)
            'm.relates_to': {
              'rel_type': RelationshipTypes.thread,
              'event_id': r'$root',
            },
        },
        eventId: eventId,
        senderId: sender,
        originServerTs: DateTime.utc(2026, 11, 6),
        room: room,
      );

  /// [eventsNewestFirst] as `timeline.events` gives them.
  String? separatorOn(List<Event> eventsNewestFirst) =>
      ThreadRules.unreadSeparatorEventId(
        eventsNewestFirst,
        fullyReadEventId: fullyRead,
        ownUserId: me,
        isVisible: EventVisibilityResolver.isVisibleInTimeline,
      );

  test('the separator sits on the oldest unread message', () {
    expect(
      separatorOn([event(r'$new2'), event(r'$new1'), event(fullyRead)]),
      r'$new1',
    );
  });

  test('an oldest unread thread reply gives the separator to the next '
      'message of the room', () {
    expect(
      separatorOn([
        event(r'$main'),
        event(r'$reply', inThread: true),
        event(fullyRead),
      ]),
      r'$main',
    );
  });

  test('no separator when only thread replies are unread', () {
    expect(
      separatorOn([
        event(r'$reply2', inThread: true),
        event(r'$reply1', inThread: true),
        event(fullyRead),
      ]),
      isNull,
    );
  });

  test('the messages of the user are not unread', () {
    expect(
      separatorOn([event(r'$mine', sender: me), event(fullyRead)]),
      isNull,
    );
  });

  test('no separator when the read marker is not in the loaded events', () {
    expect(separatorOn([event(r'$new2'), event(r'$new1')]), isNull);
  });

  test('no separator when the read marker is on the last event', () {
    expect(separatorOn([event(fullyRead), event(r'$older')]), isNull);
  });
}

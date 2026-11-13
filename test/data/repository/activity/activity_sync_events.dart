import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/model/thread/thread_ref.dart';

import '../../datasource_impl/thread/thread_account.dart';

/// The events the specs of the Activity give the sync, as the server sends
/// them (JSON of the spec), on one test day: 12 November 2026, UTC.

/// `9.utc`: 9 o'clock on the test day.
extension TestDayHour on int {
  DateTime get utc => DateTime.utc(2026, 11, 12, this);
}

/// `(9, 20).utc`: 9:20 on the test day.
extension TestDayTime on (int, int) {
  DateTime get utc => DateTime.utc(2026, 11, 12, $1, $2);
}

/// A message: its event id, who sent it, what it says and when.
typedef Said = ({String id, String sender, String body, DateTime at});

/// A member of the room and the name it shows.
typedef Person = ({String id, String name});

Map<String, Object?> messageEvent(Said said) => {
  'type': EventTypes.Message,
  'event_id': said.id,
  'sender': said.sender,
  'origin_server_ts': said.at.millisecondsSinceEpoch,
  'content': {'msgtype': 'm.text', 'body': said.body},
};

/// [said] as a reply in [thread].
Map<String, Object?> threadReplyEvent(Said said, ThreadRef thread) => {
  ...messageEvent(said),
  'content': {
    'msgtype': 'm.text',
    'body': said.body,
    'm.relates_to': {
      'rel_type': RelationshipTypes.thread,
      'event_id': thread.rootEventId,
      'is_falling_back': true,
      'm.in_reply_to': {'event_id': thread.rootEventId},
    },
  },
};

/// [person] joined, with the name it shows.
Map<String, Object?> memberEvent(Person person) => {
  'type': EventTypes.RoomMember,
  'state_key': person.id,
  'sender': person.id,
  'event_id': '\$member${person.id}',
  'origin_server_ts': 8.utc.millisecondsSinceEpoch,
  'content': {'membership': 'join', 'displayname': person.name},
};

/// The team room is named « Team ».
final Map<String, Object?> teamNameEvent = {
  'type': EventTypes.RoomName,
  'state_key': '',
  'sender': threadOwner,
  'event_id': r'$nameTeam',
  'origin_server_ts': 8.utc.millisecondsSinceEpoch,
  'content': {'name': 'Team'},
};

/// Lets the lookups, the root reads and the streams run: returns once
/// [seen] got nothing new for 1.2 s, longer than the 1 s rate limit of the
/// Activity (8 s at most).
Future<void> settle(List<Object?> seen) async {
  final deadline = DateTime.now().add(const Duration(seconds: 8));
  var count = -1;
  var quiet = 0;
  while (quiet < 60 && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    quiet = seen.length == count ? quiet + 1 : 0;
    count = seen.length;
  }
}

/// The same instant, whatever the time zone the SDK gives the date in.
Matcher sameInstant(DateTime expected) => predicate<DateTime>(
  (actual) => actual.isAtSameMomentAs(expected),
  'the instant $expected',
);

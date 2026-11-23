import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/utils/message_notification_decision.dart';

/// A message from Alice in a normal room, app in the background.
const _fromAlice = MessageNotificationCandidate(
  roomId: '!room:example.com',
  senderId: '@alice:example.com',
  ownUserId: '@me:example.com',
  eventType: EventTypes.Message,
  notificationCount: 1,
  highlightCount: 0,
  isRoomMuted: false,
  activeRoomId: null,
  appInForeground: false,
);

const _encrypted = MessageNotificationCandidate(
  roomId: '!room:example.com',
  senderId: '@alice:example.com',
  ownUserId: '@me:example.com',
  eventType: EventTypes.Encrypted,
  notificationCount: 1,
  highlightCount: 0,
  isRoomMuted: false,
  activeRoomId: null,
  appInForeground: false,
);

const _fromMe = MessageNotificationCandidate(
  roomId: '!room:example.com',
  senderId: '@me:example.com',
  ownUserId: '@me:example.com',
  eventType: EventTypes.Message,
  notificationCount: 1,
  highlightCount: 0,
  isRoomMuted: false,
  activeRoomId: null,
  appInForeground: false,
);

const _membership = MessageNotificationCandidate(
  roomId: '!room:example.com',
  senderId: '@alice:example.com',
  ownUserId: '@me:example.com',
  eventType: EventTypes.RoomMember,
  notificationCount: 1,
  highlightCount: 0,
  isRoomMuted: false,
  activeRoomId: null,
  appInForeground: false,
);

const _reaction = MessageNotificationCandidate(
  roomId: '!room:example.com',
  senderId: '@alice:example.com',
  ownUserId: '@me:example.com',
  eventType: EventTypes.Reaction,
  notificationCount: 1,
  highlightCount: 0,
  isRoomMuted: false,
  activeRoomId: null,
  appInForeground: false,
);

const _muted = MessageNotificationCandidate(
  roomId: '!room:example.com',
  senderId: '@alice:example.com',
  ownUserId: '@me:example.com',
  eventType: EventTypes.Message,
  notificationCount: 1,
  highlightCount: 0,
  isRoomMuted: true,
  activeRoomId: null,
  appInForeground: false,
);

const _mutedMention = MessageNotificationCandidate(
  roomId: '!room:example.com',
  senderId: '@alice:example.com',
  ownUserId: '@me:example.com',
  eventType: EventTypes.Message,
  notificationCount: 1,
  highlightCount: 1,
  isRoomMuted: true,
  activeRoomId: null,
  appInForeground: false,
);

const _notCounted = MessageNotificationCandidate(
  roomId: '!room:example.com',
  senderId: '@alice:example.com',
  ownUserId: '@me:example.com',
  eventType: EventTypes.Message,
  notificationCount: 0,
  highlightCount: 0,
  isRoomMuted: false,
  activeRoomId: null,
  appInForeground: false,
);

const _openInForeground = MessageNotificationCandidate(
  roomId: '!a:example.com',
  senderId: '@alice:example.com',
  ownUserId: '@me:example.com',
  eventType: EventTypes.Message,
  notificationCount: 1,
  highlightCount: 0,
  isRoomMuted: false,
  activeRoomId: '!a:example.com',
  appInForeground: true,
);

const _openInBackground = MessageNotificationCandidate(
  roomId: '!a:example.com',
  senderId: '@alice:example.com',
  ownUserId: '@me:example.com',
  eventType: EventTypes.Message,
  notificationCount: 1,
  highlightCount: 0,
  isRoomMuted: false,
  activeRoomId: '!a:example.com',
  appInForeground: false,
);

const _otherRoomInForeground = MessageNotificationCandidate(
  roomId: '!b:example.com',
  senderId: '@alice:example.com',
  ownUserId: '@me:example.com',
  eventType: EventTypes.Message,
  notificationCount: 1,
  highlightCount: 0,
  isRoomMuted: false,
  activeRoomId: '!a:example.com',
  appInForeground: true,
);

const _signedOut = MessageNotificationCandidate(
  roomId: '!r:example.com',
  senderId: '@alice:example.com',
  ownUserId: null,
  eventType: EventTypes.Message,
  notificationCount: 1,
  highlightCount: 0,
  isRoomMuted: false,
  activeRoomId: null,
  appInForeground: false,
);

/// (behaviour, candidate, should notify)
const _cases = <(String, MessageNotificationCandidate, bool)>[
  ('a message from someone else in a normal room notifies', _fromAlice, true),
  ('an encrypted message from someone else notifies', _encrypted, true),
  ('my own message never notifies', _fromMe, false),
  (
    'a membership event is not a message and never notifies',
    _membership,
    false,
  ),
  ('a reaction is not a message and never notifies', _reaction, false),
  ('a muted room stays silent', _muted, false),
  ('a muted room still notifies for a mention', _mutedMention, true),
  (
    'a message that the push rules do not count stays silent',
    _notCounted,
    false,
  ),
  (
    'the room open in the foreground app stays silent',
    _openInForeground,
    false,
  ),
  (
    'the open room notifies when the app is in the background',
    _openInBackground,
    true,
  ),
  (
    'another room notifies while the app is in the foreground',
    _otherRoomInForeground,
    true,
  ),
];

void main() {
  group('shouldNotifyMessage', () {
    for (final (behaviour, candidate, expected) in _cases) {
      test(behaviour, () {
        expect(shouldNotifyMessage(candidate), expected);
      });
    }

    test('a signed-out account (no own user id) still notifies', () {
      expect(shouldNotifyMessage(_signedOut), isTrue);
    });
  });
}

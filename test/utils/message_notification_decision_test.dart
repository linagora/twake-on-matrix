import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/utils/message_notification_decision.dart';

MessageNotificationCandidate candidate({
  String roomId = '!room:example.com',
  String senderId = '@alice:example.com',
  String ownUserId = '@me:example.com',
  String eventType = EventTypes.Message,
  int notificationCount = 1,
  int highlightCount = 0,
  bool isRoomMuted = false,
  String? activeRoomId,
  bool appInForeground = false,
}) => MessageNotificationCandidate(
  roomId: roomId,
  senderId: senderId,
  ownUserId: ownUserId,
  eventType: eventType,
  notificationCount: notificationCount,
  highlightCount: highlightCount,
  isRoomMuted: isRoomMuted,
  activeRoomId: activeRoomId,
  appInForeground: appInForeground,
);

void main() {
  group('shouldNotifyMessage', () {
    test('a message from someone else in a normal room notifies', () {
      expect(shouldNotifyMessage(candidate()), isTrue);
    });

    test('an encrypted message from someone else notifies', () {
      expect(
        shouldNotifyMessage(candidate(eventType: EventTypes.Encrypted)),
        isTrue,
      );
    });

    test('my own message never notifies', () {
      expect(
        shouldNotifyMessage(candidate(senderId: '@me:example.com')),
        isFalse,
      );
    });

    test('an event that is not a message never notifies', () {
      expect(
        shouldNotifyMessage(candidate(eventType: EventTypes.RoomMember)),
        isFalse,
      );
      expect(
        shouldNotifyMessage(candidate(eventType: EventTypes.Reaction)),
        isFalse,
      );
    });

    test('a muted room stays silent', () {
      expect(shouldNotifyMessage(candidate(isRoomMuted: true)), isFalse);
    });

    test('a muted room still notifies for a mention', () {
      expect(
        shouldNotifyMessage(candidate(isRoomMuted: true, highlightCount: 1)),
        isTrue,
      );
    });

    test('a message that the push rules do not count stays silent', () {
      expect(shouldNotifyMessage(candidate(notificationCount: 0)), isFalse);
    });

    test('the room open in the foreground app stays silent', () {
      expect(
        shouldNotifyMessage(
          candidate(
            roomId: '!a:example.com',
            activeRoomId: '!a:example.com',
            appInForeground: true,
          ),
        ),
        isFalse,
      );
    });

    test('the open room notifies when the app is in the background', () {
      expect(
        shouldNotifyMessage(
          candidate(
            roomId: '!a:example.com',
            activeRoomId: '!a:example.com',
            appInForeground: false,
          ),
        ),
        isTrue,
      );
    });

    test('another room notifies while the app is in the foreground', () {
      expect(
        shouldNotifyMessage(
          candidate(
            roomId: '!b:example.com',
            activeRoomId: '!a:example.com',
            appInForeground: true,
          ),
        ),
        isTrue,
      );
    });

    test('a signed-out account (no own user id) still notifies', () {
      expect(
        shouldNotifyMessage(
          const MessageNotificationCandidate(
            roomId: '!r:example.com',
            senderId: '@alice:example.com',
            ownUserId: null,
            eventType: EventTypes.Message,
            notificationCount: 1,
            highlightCount: 0,
            isRoomMuted: false,
            activeRoomId: null,
            appInForeground: false,
          ),
        ),
        isTrue,
      );
    });
  });
}

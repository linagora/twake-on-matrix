import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/model/extensions/push/push_notification_extension.dart';

void main() {
  group('PushNotificationExtensions.fromOriginalJson counts', () {
    test('parses string counts sent by FCM v1', () {
      final notification = PushNotificationExtensions().fromOriginalJson({
        'room_id': '!room:server',
        'unread': '0',
        'missed_calls': '2',
      });

      expect(notification.counts?.unread, 0);
      expect(notification.counts?.missedCalls, 2);
    });

    test('parses int counts', () {
      final notification = PushNotificationExtensions().fromOriginalJson({
        'unread': 3,
      });

      expect(notification.counts?.unread, 3);
    });

    test('returns null counts when none are sent', () {
      final notification = PushNotificationExtensions().fromOriginalJson({
        'event_id': r'$event',
      });

      expect(notification.counts, isNull);
    });
  });
}

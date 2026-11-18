import 'dart:convert';

import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/model/push/twake_local_notification_payload.dart';
import 'package:twake_chat/utils/message_notification_decision.dart';

/// The part of the notification plugin the notifier needs.
abstract class LocalNotificationsPort {
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String payload,
  });
}

class MessageNotificationContent {
  const MessageNotificationContent({
    required this.roomTitle,
    required this.senderName,
    required this.body,
    required this.eventId,
    required this.isDirectChat,
  });

  final String roomTitle;
  final String senderName;
  final String body;
  final String eventId;
  final bool isDirectChat;
}

/// Shows one local notification per incoming message on macOS.
class MacosMessageNotifier {
  MacosMessageNotifier(
    this._port, {
    required this.receiverId,
    required this.genericBody,
  });

  final LocalNotificationsPort _port;
  final String receiverId;
  final String genericBody;

  /// Returns whether a notification was shown. Never throws.
  Future<bool> notify(
    MessageNotificationCandidate candidate,
    MessageNotificationContent content, {
    required bool showPreview,
  }) async {
    if (!shouldNotifyMessage(candidate)) return false;
    final body = !showPreview
        ? genericBody
        : content.isDirectChat
        ? content.body
        : '${content.senderName}: ${content.body}';
    try {
      await _port.show(
        // Stable per room, so a new message replaces the previous one.
        id: candidate.roomId.hashCode & 0x7fffffff,
        title: content.roomTitle,
        body: body,
        payload: jsonEncode(
          TwakeLocalNotificationPayload(
            roomId: candidate.roomId,
            receiverId: receiverId,
            eventId: content.eventId,
          ).toJson(),
        ),
      );
      return true;
    } catch (e, s) {
      Logs().w('[Notifications] macOS notification failed', e, s);
      return false;
    }
  }
}

import 'dart:convert';

import 'package:matrix/matrix.dart';

class PushNotificationExtensions {
  static const _error = 'error';

  PushNotification error() {
    return const PushNotification(
      devices: [],
      eventId: _error,
      roomId: _error,
      type: _error,
    );
  }

  PushNotification fromOriginalJson(Map<String, dynamic> json) {
    return PushNotification(
      content: json['content'] is Map
          ? Map<String, dynamic>.from(json['content'])
          : json['content'] is String
              ? jsonDecode(json['content'])
              : null,
      counts: _extractCounts(json),
      devices: [],
      eventId: json['event_id'],
      prio: json['prio'],
      roomAlias: json['room_alias'],
      roomId: json['room_id'],
      roomName: json['room_name'],
      sender: json['sender'],
      senderDisplayName: json['sender_display_name'],
      type: json['type'],
    );
  }

  void validate(PushNotification notification) {
    if (notification.eventId == _error ||
        notification.type == _error ||
        notification.roomId == _error) {
      throw ArgumentError('Invalid push notification');
    }
  }

  PushNotificationCounts? _extractCounts(Map<String, dynamic> json) {
    final unread = json['unread'] is int ? json['unread'] : null;
    final missedCalls =
        json['missed_calls'] is int ? json['missed_calls'] : null;

    if (unread != null || missedCalls != null) {
      return PushNotificationCounts(
        missedCalls: missedCalls,
        unread: unread,
      );
    }
    return null;
  }
}

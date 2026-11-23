import 'dart:convert';

import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/model/room/room_extension.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/matrix_locals.dart';
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

  Future<void> cancel(int id);
}

/// Stable id of the notification of [roomId] (FNV-1a, 31 bits): the same for
/// show and cancel, so a new message replaces the previous one of the room.
int macosNotificationId(String roomId) {
  var h = 0x811c9dc5;
  for (final c in roomId.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0xffffffff;
  }
  return h & 0x7fffffff;
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

/// Shows the local notification of a room on macOS: a new message replaces
/// the previous one of the same room.
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
        id: macosNotificationId(candidate.roomId),
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

  /// Removes the notification of [roomId] (read elsewhere). Never throws.
  Future<void> cancelRoom(String roomId) async {
    try {
      await _port.cancel(macosNotificationId(roomId));
    } catch (e, s) {
      Logs().w('[Notifications] macOS notification cancel failed', e, s);
    }
  }
}

/// What the app shows right now, and whether the text may be shown.
class MacosNotificationState {
  const MacosNotificationState({
    required this.activeRoomId,
    required this.appInForeground,
    required this.showPreview,
  });

  final String? activeRoomId;
  final bool appInForeground;
  final bool showPreview;
}

/// An [eventUpdate] read on the [client] it came from (the event account, not
/// the active one).
class MacosMessageRequest {
  const MacosMessageRequest({
    required this.client,
    required this.eventUpdate,
    required this.l10n,
    required this.state,
  });

  final Client client;
  final EventUpdate eventUpdate;
  final L10n l10n;
  final MacosNotificationState state;
}

/// Notifies the user of the [request]. Returns whether one was shown.
Future<bool> notifyMacosMessage(
  LocalNotificationsPort port,
  MacosMessageRequest request,
) async {
  final client = request.client;
  final eventUpdate = request.eventUpdate;
  final l10n = request.l10n;
  final room = client.getRoomById(eventUpdate.roomID);
  if (room == null) return false;
  final candidate = MessageNotificationCandidate(
    roomId: room.id,
    senderId: eventUpdate.content['sender'] as String? ?? '',
    ownUserId: client.userID,
    eventType: eventUpdate.content['type'] as String? ?? '',
    notificationCount: room.notificationCount,
    highlightCount: room.highlightCount,
    isRoomMuted: room.isMuted,
    activeRoomId: request.state.activeRoomId,
    appInForeground: request.state.appInForeground,
  );
  if (!shouldNotifyMessage(candidate)) return false;
  final locals = MatrixLocals(l10n);
  final event = Event.fromJson(eventUpdate.content, room);
  // The text is read only when it may be shown: never for an encrypted room.
  final withText = request.state.showPreview && !room.encrypted;
  final body = withText
      ? await event.calcLocalizedBody(
          locals,
          withSenderNamePrefix: false,
          plaintextBody: true,
          hideReply: true,
          hideEdit: true,
          removeMarkdown: true,
        )
      : '';
  return MacosMessageNotifier(
    port,
    receiverId: client.userID ?? '',
    genericBody: l10n.newMessage,
  ).notify(
    candidate,
    MessageNotificationContent(
      roomTitle: room.getLocalizedDisplayname(locals),
      senderName: withText ? _senderName(room, event) : '',
      body: body,
      eventId: event.eventId,
      isDirectChat: room.isDirectChat,
    ),
    showPreview: withText,
  );
}

/// From the member state in memory: no request, nothing awaited.
String _senderName(Room room, Event event) =>
    room.getState(EventTypes.RoomMember, event.senderId)?.content['displayname']
        as String? ??
    event.senderId.localpart ??
    event.senderId;

import 'package:matrix/matrix.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/thread/thread_rules.dart';

/// Where a tapped notification leads: a thread reply opens its thread screen
/// on that reply (room beneath), anything else opens the room, on the event
/// when there is one. The ids go through the typed routes, so an event id of
/// a v3 room (`+`, `/`) survives the query string.
String notificationLocation({
  required String roomId,
  String? eventId,
  String? threadRootId,
}) => threadRootId != null && eventId != null
    ? ThreadRoute(roomid: roomId, rootid: threadRootId, event: eventId).location
    : RoomRoute(roomid: roomId, event: eventId).location;

/// [notificationLocation] for a tap, which knows the room and the event id
/// only: the event tells whether it is a thread reply. An event that cannot
/// be loaded opens the room on it, as before threads.
Future<String> resolveNotificationLocation(
  Client client,
  String roomId, {
  String? eventId,
}) async => notificationLocation(
  roomId: roomId,
  eventId: eventId,
  threadRootId: await _threadRootOfEvent(client, roomId, eventId),
);

Future<String?> _threadRootOfEvent(
  Client client,
  String roomId,
  String? eventId,
) async {
  if (eventId == null) return null;
  final event = await _loadEvent(client, roomId, eventId);
  return event == null ? null : ThreadRules.threadRootOf(event);
}

Future<Event?> _loadEvent(Client client, String roomId, String eventId) async {
  try {
    return await client
        .getRoomById(roomId)
        ?.getEventById(eventId)
        .timeout(const Duration(seconds: 5));
  } catch (e, s) {
    Logs().w('[Push] Unable to load the event of the notification', e, s);
    return null;
  }
}

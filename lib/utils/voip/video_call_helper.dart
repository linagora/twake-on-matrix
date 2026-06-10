import 'dart:async';
import 'dart:math';

import 'package:matrix/matrix.dart';

class VideoCallHelper {
  const VideoCallHelper._();

  static const _slugAlphabet = 'abcdefghijklmnopqrstuvwxyz';
  static const callUrlKey = 'call_url';
  static const widgetName = 'Video call';
  static const widgetsLayoutEventType = 'io.element.widgets.layout';

  static final RegExp _slugRegExp = RegExp(r'^[a-z]{3}-[a-z]{4}-[a-z]{3}$');

  static String? extractUrl(Event event, String? baseUrl) {
    if (baseUrl == null || baseUrl.isEmpty) return null;
    if (event.messageType != MessageTypes.Text) return null;
    final url = event.content.tryGet<String>(callUrlKey);
    if (url == null || url.isEmpty) return null;
    final prefix = '$baseUrl/';
    if (!url.startsWith(prefix)) return null;
    if (!_slugRegExp.hasMatch(url.substring(prefix.length))) return null;
    return url;
  }

  static String generateUrl(String baseUrl) {
    final random = Random.secure();
    String letters(int length) => List.generate(
      length,
      (_) => _slugAlphabet[random.nextInt(_slugAlphabet.length)],
    ).join();
    final slug = '${letters(3)}-${letters(4)}-${letters(3)}';
    return '$baseUrl/$slug';
  }

  /// Returns the call URL of a call already advertised in the room state,
  /// if any, so that tapping the call button joins it instead of starting
  /// a parallel meeting.
  static String? ongoingCallUrl(Room room, String baseUrl) {
    for (final widget in room.widgets) {
      if (widget.url.startsWith('$baseUrl/')) return widget.url;
    }
    return null;
  }

  static String? start({required Room? room, required String? baseUrl}) {
    if (room == null || baseUrl == null) return null;

    final ongoingUrl = ongoingCallUrl(room, baseUrl);
    if (ongoingUrl != null) {
      Logs().i('VideoCall: joining ongoing call $ongoingUrl');
      return ongoingUrl;
    }

    final url = generateUrl(baseUrl);
    Logs().i('VideoCall: starting new call $url');
    // MSC1236: advertise the call as a room widget so other members and
    // Matrix clients (Element, ...) can see and join it. Requires the power
    // level for state events, so a failure must not block the call itself.
    unawaited(
      _publishWidget(room, url).catchError((error) {
        Logs().w('Could not publish video call widget', error);
      }),
    );
    return url;
  }

  /// Removes the call widgets *we* created in this room (and their pinned
  /// layout). Called when the local user leaves the call: best-effort
  /// cleanup, as nothing signals when the meeting really ends (see POC
  /// limitations).
  static Future<void> cleanUpOwnCallWidgets(Room room, String baseUrl) async {
    var removed = false;
    for (final widget in room.widgets) {
      final id = widget.id;
      if (id == null) continue;
      if (!widget.url.startsWith('$baseUrl/')) continue;
      if (widget.creatorUserId != room.client.userID &&
          !id.endsWith('_${room.client.userID!}')) {
        continue;
      }
      try {
        await room.deleteWidget(id);
        removed = true;
        Logs().i('VideoCall: removed call widget $id');
      } catch (error) {
        Logs().w('VideoCall: could not remove call widget $id', error);
      }
    }
    if (removed) {
      try {
        await room.client.setRoomStateWithKey(
          room.id,
          widgetsLayoutEventType,
          '',
          {'widgets': {}},
        );
      } catch (error) {
        Logs().w('VideoCall: could not clear widget layout', error);
      }
    }
  }

  static Future<void> _publishWidget(Room room, String url) async {
    await room.addWidget(
      MatrixWidget(
        room: room,
        name: widgetName,
        type: 'm.video',
        url: url,
        data: {'url': url},
        // Meet does not implement the widget postMessage API, so it
        // never sends `content_loaded`. Tell clients to rely on the
        // iframe load event instead (otherwise Element shows an
        // infinite loading spinner).
        waitForIframeLoad: false,
      ),
    );
    // Pin the widget to the top of the room for everyone, so Element
    // shows the call above the timeline instead of burying it in the
    // room settings. Must match the widget id computed by addWidget().
    final widgetId =
        '${widgetName.toLowerCase().replaceAll(RegExp(r'\W'), '_')}_${room.client.userID!}';
    await room.client.setRoomStateWithKey(room.id, widgetsLayoutEventType, '', {
      'widgets': {
        widgetId: {'container': 'top', 'index': 0, 'width': 100, 'height': 60},
      },
    });
  }
}

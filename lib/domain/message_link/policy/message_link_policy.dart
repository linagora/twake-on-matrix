/// Decides which link the user copies to point at one message.
class MessageLinkPolicy {
  const MessageLinkPolicy();

  static const String _matrixToPrefix = 'https://matrix.to/#/';

  /// Returns `<webAppOrigin>/rooms/<roomId>?event=<eventId>`, the link the
  /// Twake Chat web app copies, when [webAppOrigin] is known. Otherwise a
  /// matrix.to permalink, as described in
  /// https://spec.matrix.org/v1.16/appendices/#matrixto-navigation, with the
  /// server of [userId] (the only one sure to be in the room), then the room
  /// server, as `via`: a room id alone is not routable
  /// (https://spec.matrix.org/v1.16/appendices/#routing).
  String build({
    required String? webAppOrigin,
    required String roomId,
    required String eventId,
    String? userId,
  }) {
    final room = Uri.encodeComponent(roomId);
    final event = Uri.encodeComponent(eventId);
    if (webAppOrigin != null) {
      return '$webAppOrigin/rooms/$room?event=$event';
    }
    return '$_matrixToPrefix$room/$event${_viaQuery(roomId, userId)}';
  }

  /// The user's server, then the room id's: a room v12 id names none.
  String _viaQuery(String roomId, String? userId) {
    final servers = {
      if (userId != null) ?_serverOf(userId),
      ?_serverOf(roomId),
    };
    if (servers.isEmpty) return '';
    return '?${servers.map((s) => 'via=${Uri.encodeComponent(s)}').join('&')}';
  }

  String? _serverOf(String id) {
    final colon = id.indexOf(':');
    return colon == -1 ? null : id.substring(colon + 1);
  }

  /// Returns the matrix.to link of [link] when it is a room or message link
  /// of the web app served at [webAppOrigin] (`<origin>/rooms/<room>`,
  /// optionally `?event=<event>`), as the web app reads them; otherwise null.
  String? matrixToForWebLink(String link, {required String? webAppOrigin}) {
    if (webAppOrigin == null || !link.startsWith('$webAppOrigin/')) {
      return null;
    }
    final uri = Uri.tryParse(link);
    return uri == null ? null : _matrixToForRoomsPath(uri);
  }

  /// Returns the matrix.to link of an `https://<any host>/rooms/<roomId>`
  /// link (optionally `?event=<event>`) when [isKnownRoom] knows its room id:
  /// the web app of a homeserver that does not name it in `web_url`.
  /// Otherwise null, so links of other sites keep opening in the browser.
  String? matrixToForRoomsLink(
    String link, {
    required bool Function(String roomId) isKnownRoom,
  }) {
    final uri = Uri.tryParse(link);
    if (uri == null || uri.scheme != 'https') return null;
    final matrixTo = _matrixToForRoomsPath(uri);
    if (matrixTo == null) return null;
    final roomId = uri.pathSegments.last;
    if (!roomId.startsWith('!') || !isKnownRoom(roomId)) return null;
    return matrixTo;
  }

  /// Null when the path or query is not valid percent-encoded UTF-8: such a
  /// link keeps opening in the browser.
  String? _matrixToForRoomsPath(Uri uri) {
    try {
      final segments = uri.pathSegments;
      if (segments.length != 2 || segments.first != 'rooms') return null;
      if (segments.last.isEmpty) return null;
      final room = Uri.encodeComponent(segments.last);
      final eventId = uri.queryParameters['event'];
      if (eventId == null || eventId.isEmpty) return '$_matrixToPrefix$room';
      return '$_matrixToPrefix$room/${Uri.encodeComponent(eventId)}';
    } on FormatException {
      return null;
    }
  }
}

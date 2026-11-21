/// Builds the link the user copies to point at one message, and reads the
/// message links of the Twake Chat web app.
class MessageLinkPolicy {
  const MessageLinkPolicy();

  static const String _matrixToPrefix = 'https://matrix.to/#/';

  /// Returns the matrix.to permalink of [eventId] in [roomId], as described
  /// in https://spec.matrix.org/v1.16/appendices/#matrixto-navigation, with
  /// the server of [userId] (the only one sure to be in the room), then the
  /// room server, as `via`: a room id alone is not routable
  /// (https://spec.matrix.org/v1.16/appendices/#routing).
  String build({
    required String roomId,
    required String eventId,
    String? userId,
  }) {
    final room = Uri.encodeComponent(roomId);
    final event = Uri.encodeComponent(eventId);
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

  /// Returns the matrix.to link of an `https://<any host>/rooms/<room id or
  /// alias>` link (optionally `?event=<event>` and `via=`), the link the
  /// Twake Chat web app copies. A room the user is not in opens the preview
  /// sheet. Otherwise null, so links of other sites keep opening in the
  /// browser.
  String? matrixToForRoomsLink(String link) {
    final uri = Uri.tryParse(link);
    if (uri == null || uri.scheme != 'https') return null;
    return _matrixToForRoomsPath(uri);
  }

  /// Null when the path or query is not valid percent-encoded UTF-8: such a
  /// link keeps opening in the browser.
  String? _matrixToForRoomsPath(Uri uri) {
    try {
      final segments = uri.pathSegments;
      if (segments.length != 2 || segments.first != 'rooms') return null;
      final id = segments.last;
      final colon = id.indexOf(':');
      final isAlias = id.startsWith('#') && colon > 1 && colon < id.length - 1;
      if (!id.startsWith('!') && !isAlias) return null;
      final eventId = uri.queryParameters['event'];
      final via = uri.queryParametersAll['via'] ?? const [];
      return '$_matrixToPrefix${Uri.encodeComponent(id)}'
          '${eventId == null || eventId.isEmpty ? '' : '/${Uri.encodeComponent(eventId)}'}'
          '${via.isEmpty ? '' : '?${via.map((s) => 'via=${Uri.encodeComponent(s)}').join('&')}'}';
    } on FormatException {
      return null;
    }
  }
}

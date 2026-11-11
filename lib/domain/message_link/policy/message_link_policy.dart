/// Decides which link the user copies to point at one message.
class MessageLinkPolicy {
  const MessageLinkPolicy();

  static const String _matrixToPrefix = 'https://matrix.to/#/';

  /// Returns `<webAppOrigin>/rooms/<roomId>?event=<eventId>`, the link the
  /// Twake Chat web app copies, when [webAppOrigin] is known. Otherwise a
  /// matrix.to permalink, as described in
  /// https://spec.matrix.org/v1.16/appendices/#matrixto-navigation
  String build({
    required String? webAppOrigin,
    required String roomId,
    required String eventId,
  }) {
    final room = Uri.encodeComponent(roomId);
    final event = Uri.encodeComponent(eventId);
    if (webAppOrigin != null) {
      return '$webAppOrigin/rooms/$room?event=$event';
    }
    return '$_matrixToPrefix$room/$event';
  }

  /// Returns the matrix.to link of [link] when it is a room or message link
  /// of the web app served at [webAppOrigin] (`<origin>/rooms/<room>`,
  /// optionally `?event=<event>`), as the web app reads them; otherwise null.
  String? matrixToForWebLink(String link, {required String? webAppOrigin}) {
    if (webAppOrigin == null || !link.startsWith('$webAppOrigin/')) {
      return null;
    }
    final uri = Uri.tryParse(link);
    if (uri == null) return null;
    final segments = uri.pathSegments;
    if (segments.length != 2 || segments.first != 'rooms') return null;
    final room = Uri.encodeComponent(segments.last);
    final eventId = uri.queryParameters['event'];
    if (eventId == null || eventId.isEmpty) return '$_matrixToPrefix$room';
    return '$_matrixToPrefix$room/${Uri.encodeComponent(eventId)}';
  }
}

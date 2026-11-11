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
}

import 'package:matrix/matrix.dart';

extension ActivityEventExtension on Event {
  /// The text a line of the Activity shows: without the quote of a reply nor
  /// the marks of an edit.
  String get activityText =>
      calcUnlocalizedBody(hideReply: true, hideEdit: true);

  /// An event the server gave as it stores it, decrypted when it can be.
  Future<Event> decryptedBy(Client client) async {
    if (type != EventTypes.Encrypted || !client.encryptionEnabled) return this;
    try {
      return await client.encryption!.decryptRoomEvent(this);
    } catch (_) {
      return this;
    }
  }
}

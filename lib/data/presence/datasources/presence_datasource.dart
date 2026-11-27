import 'package:twake_chat/domain/presence/entities/person_presence.dart';

abstract class PresenceDatasource {
  /// Emits the presence of [userId] now, then on every change; null while
  /// there is no account. [readFromServer] refreshes the cached value once.
  Stream<PersonPresence?> watchPresence(
    String userId, {
    required bool readFromServer,
  });
}

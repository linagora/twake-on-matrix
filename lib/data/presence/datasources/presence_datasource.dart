import 'package:twake_chat/domain/presence/entities/person_presence.dart';

abstract class PresenceDatasource {
  /// Emits the presence of [userId] now, then on every change; null while
  /// there is no account.
  Stream<PersonPresence?> watchPresence(String userId);
}

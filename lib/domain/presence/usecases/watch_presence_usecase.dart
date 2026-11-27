import 'package:twake_chat/domain/presence/entities/person_presence.dart';
import 'package:twake_chat/domain/presence/repositories/presence_repository.dart';

class WatchPresenceUseCase {
  const WatchPresenceUseCase(this._repository);

  final PresenceRepository _repository;

  /// Emits the presence of [userId] now and on every change; a blank id has
  /// none.
  Stream<PersonPresence?> execute(
    String userId, {
    required bool readFromServer,
  }) {
    if (userId.isEmpty) return Stream.value(null);
    return _repository
        .watchPresence(userId, readFromServer: readFromServer)
        .distinct();
  }
}

import 'package:twake_chat/domain/repository/public_rooms/public_rooms_repository.dart';

class KnockPublicRoomUseCase {
  const KnockPublicRoomUseCase(this._repository);

  final PublicRoomsRepository _repository;

  /// Throws a `PublicRoomKnockFailedException`.
  Future<void> execute(String roomIdOrAlias, {List<String> via = const []}) =>
      _repository.knock(roomIdOrAlias, via: via);
}

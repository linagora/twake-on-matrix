import 'package:twake_chat/domain/repository/public_rooms/public_rooms_repository.dart';

class JoinPublicRoomUseCase {
  const JoinPublicRoomUseCase(this._repository);

  final PublicRoomsRepository _repository;

  /// Throws a `PublicRoomJoinFailedException`.
  Future<({String roomId, bool isInSync})> execute(String roomIdOrAlias) =>
      _repository.join(roomIdOrAlias);
}

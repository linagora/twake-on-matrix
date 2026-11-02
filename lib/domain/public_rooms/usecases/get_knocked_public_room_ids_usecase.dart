import 'package:twake_chat/domain/repository/public_rooms/public_rooms_repository.dart';

class GetKnockedPublicRoomIdsUseCase {
  const GetKnockedPublicRoomIdsUseCase(this._repository);

  final PublicRoomsRepository _repository;

  /// The rooms among [roomIds] where the user's join request is pending.
  Future<Set<String>> execute(List<String> roomIds) =>
      _repository.getKnockedRoomIds(roomIds);
}

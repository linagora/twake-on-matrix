import 'package:twake_chat/domain/repository/room_access/room_access_repository.dart';
import 'package:twake_chat/domain/room_access/entities/room_access.dart';

class GetRoomAccessUseCase {
  const GetRoomAccessUseCase(this._roomAccessRepository);

  final RoomAccessRepository _roomAccessRepository;

  Future<RoomAccess> execute(String roomId) =>
      _roomAccessRepository.getRoomAccess(roomId);
}

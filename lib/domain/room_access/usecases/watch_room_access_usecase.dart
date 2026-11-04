import 'package:twake_chat/domain/room_access/entities/room_access.dart';
import 'package:twake_chat/domain/room_access/repositories/room_access_repository.dart';

class WatchRoomAccessUseCase {
  const WatchRoomAccessUseCase(this._roomAccessRepository);

  final RoomAccessRepository _roomAccessRepository;

  Stream<RoomAccess> execute(String roomId) =>
      _roomAccessRepository.watchRoomAccess(roomId);
}

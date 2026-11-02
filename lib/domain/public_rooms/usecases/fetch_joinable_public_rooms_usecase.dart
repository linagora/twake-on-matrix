import 'package:twake_chat/domain/model/public_rooms/public_room.dart';
import 'package:twake_chat/domain/repository/public_rooms/public_rooms_repository.dart';

class FetchJoinablePublicRoomsUseCase {
  const FetchJoinablePublicRoomsUseCase(this._repository);

  static const directoryLimit = 1000;

  static const _listedKinds = {PublicRoomKind.group, PublicRoomKind.feed};

  final PublicRoomsRepository _repository;

  /// The groups and feeds of the homeserver directory the user has not joined.
  Future<List<PublicRoom>> execute() async {
    final rooms = await _repository.fetchDirectory(limit: directoryLimit);
    final joined = _repository.getJoinedRoomIds();
    return rooms
        .where(
          (room) =>
              _listedKinds.contains(room.kind) && !joined.contains(room.roomId),
        )
        .toList();
  }
}

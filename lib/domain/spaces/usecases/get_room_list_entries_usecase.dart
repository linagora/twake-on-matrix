import 'package:twake_chat/domain/repository/spaces/space_repository.dart';
import 'package:twake_chat/domain/spaces/room_list_entry.dart';

class GetRoomListEntriesUseCase {
  const GetRoomListEntriesUseCase(this._repository);

  final SpaceRepository _repository;

  List<RoomListEntry> execute() => _repository.getRoomListEntries();
}

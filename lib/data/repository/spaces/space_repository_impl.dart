import 'package:twake_chat/data/datasource/spaces/space_datasource.dart';
import 'package:twake_chat/domain/repository/spaces/space_repository.dart';
import 'package:twake_chat/domain/spaces/new_space.dart';
import 'package:twake_chat/domain/spaces/room_list_entry.dart';
import 'package:twake_chat/domain/spaces/space_models.dart';

class SpaceRepositoryImpl implements SpaceRepository {
  const SpaceRepositoryImpl(this._datasource);

  final SpaceDatasource _datasource;

  @override
  Stream<int> watchRoomChanges() => _datasource.watchRoomChanges();

  @override
  List<RoomListEntry> getRoomListEntries() => _datasource.getRoomListEntries();

  @override
  SpaceSummary? getSpace(String roomId) => _datasource.getSpace(roomId);

  @override
  List<SpaceSummary> getAddableSpaces() => _datasource.getAddableSpaces();

  @override
  Future<List<SpaceChannel>> getSpaceChildren(String spaceId) =>
      _datasource.getSpaceChildren(spaceId);

  @override
  Future<void> joinRoom(String roomId, {List<String> via = const []}) =>
      _datasource.joinRoom(roomId, via: via);

  @override
  Future<void> open(String roomId) => _datasource.open(roomId);

  @override
  Future<String> createSpace(NewSpace space) => _datasource.createSpace(space);
}

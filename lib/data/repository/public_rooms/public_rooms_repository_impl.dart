import 'package:twake_chat/data/datasource/public_rooms/public_rooms_datasource.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room.dart';
import 'package:twake_chat/domain/repository/public_rooms/public_rooms_repository.dart';

class PublicRoomsRepositoryImpl implements PublicRoomsRepository {
  const PublicRoomsRepositoryImpl(this._datasource);

  final PublicRoomsDatasource _datasource;

  @override
  Future<List<PublicRoom>> fetchDirectory({required int limit}) =>
      _datasource.fetchDirectory(limit: limit);

  @override
  Set<String> getJoinedRoomIds() => _datasource.getJoinedRoomIds();

  @override
  Future<String> join(String roomIdOrAlias) => _datasource.join(roomIdOrAlias);

  @override
  Future<void> knock(String roomIdOrAlias) => _datasource.knock(roomIdOrAlias);
}

import 'package:twake_chat/data/datasource/public_rooms/public_rooms_datasource.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room.dart';
import 'package:twake_chat/domain/repository/public_rooms/public_rooms_repository.dart';

class PublicRoomsRepositoryImpl implements PublicRoomsRepository {
  const PublicRoomsRepositoryImpl(this._datasource);

  final PublicRoomsDatasource _datasource;

  @override
  Stream<List<PublicRoom>> fetchDirectory({required int limit}) =>
      _datasource.fetchDirectory(limit: limit);

  @override
  Set<String> getMemberRoomIds() => _datasource.getMemberRoomIds();

  @override
  Future<Set<String>> getKnockedRoomIds(List<String> roomIds) =>
      _datasource.getKnockedRoomIds(roomIds);

  @override
  Future<({String roomId, bool isInSync})> join(String roomIdOrAlias) =>
      _datasource.join(roomIdOrAlias);

  @override
  Future<void> knock(String roomIdOrAlias) => _datasource.knock(roomIdOrAlias);
}

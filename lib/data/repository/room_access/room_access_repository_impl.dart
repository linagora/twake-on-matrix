import 'package:twake_chat/data/datasource/room_access/room_access_datasource.dart';
import 'package:twake_chat/domain/repository/room_access/room_access_repository.dart';
import 'package:twake_chat/domain/room_access/entities/room_access.dart';

class RoomAccessRepositoryImpl implements RoomAccessRepository {
  const RoomAccessRepositoryImpl(this._roomAccessDatasource);

  final RoomAccessDatasource _roomAccessDatasource;

  @override
  Future<RoomAccess> getRoomAccess(String roomId) =>
      _roomAccessDatasource.getRoomAccess(roomId);

  @override
  bool isEncrypted(String roomId) => _roomAccessDatasource.isEncrypted(roomId);

  @override
  Future<void> setJoinRule(String roomId, JoinRuleChoice joinRule) =>
      _roomAccessDatasource.setJoinRule(roomId, joinRule);

  @override
  Future<void> setListed(String roomId, {required bool isListed}) =>
      _roomAccessDatasource.setListed(roomId, isListed: isListed);
}

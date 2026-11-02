import 'package:twake_chat/data/room_access/datasources/room_access_datasource.dart';
import 'package:twake_chat/domain/room_access/entities/room_access.dart';
import 'package:twake_chat/domain/room_access/repositories/room_access_repository.dart';

class RoomAccessRepositoryImpl implements RoomAccessRepository {
  const RoomAccessRepositoryImpl(this._roomAccessDatasource);

  final RoomAccessDatasource _roomAccessDatasource;

  @override
  Stream<RoomAccess> watchRoomAccess(String roomId) =>
      _roomAccessDatasource.watchRoomAccess(roomId);

  @override
  bool isEncrypted(String roomId) => _roomAccessDatasource.isEncrypted(roomId);

  @override
  bool hasPublicPage(String roomId) =>
      _roomAccessDatasource.hasPublicPage(roomId);

  @override
  Future<void> setJoinRule(String roomId, JoinRuleChoice joinRule) =>
      _roomAccessDatasource.setJoinRule(roomId, joinRule);

  @override
  Future<void> setListed(String roomId, {required bool isListed}) =>
      _roomAccessDatasource.setListed(roomId, isListed: isListed);
}

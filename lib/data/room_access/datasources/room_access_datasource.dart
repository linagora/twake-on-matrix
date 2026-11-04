import 'package:twake_chat/domain/room_access/entities/room_access.dart';

abstract class RoomAccessDatasource {
  /// Emits again whenever the rule, the encryption or the permission change;
  /// the listing is read from the directory at each emission.
  Stream<RoomAccess> watchRoomAccess(String roomId);

  RoomAccessGuards guardsOf(String roomId);

  Future<void> setJoinRule(String roomId, JoinRuleChoice joinRule);

  Future<void> setListed(String roomId, {required bool isListed});
}

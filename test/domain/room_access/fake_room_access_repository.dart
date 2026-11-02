import 'package:twake_chat/domain/repository/room_access/room_access_repository.dart';
import 'package:twake_chat/domain/room_access/entities/room_access.dart';

class FakeRoomAccessRepository implements RoomAccessRepository {
  FakeRoomAccessRepository({
    this.access = const RoomAccess(
      joinRule: JoinRuleChoice.invite,
      isListed: false,
      isEncrypted: false,
      canChange: true,
    ),
  });

  RoomAccess access;
  Object? setJoinRuleError;
  Object? setListedError;
  final List<String> calls = [];

  @override
  Future<RoomAccess> getRoomAccess(String roomId) async => access;

  @override
  bool isEncrypted(String roomId) => access.isEncrypted;

  @override
  Future<void> setJoinRule(String roomId, JoinRuleChoice joinRule) async {
    calls.add('joinRule:${joinRule.name}');
    if (setJoinRuleError != null) throw setJoinRuleError!;
  }

  @override
  Future<void> setListed(String roomId, {required bool isListed}) async {
    calls.add('listed:$isListed');
    if (setListedError != null) throw setListedError!;
  }
}

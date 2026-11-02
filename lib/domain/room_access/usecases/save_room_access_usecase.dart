import 'package:twake_chat/domain/room_access/exceptions/room_access_exception.dart';
import 'package:twake_chat/domain/room_access/repositories/room_access_repository.dart';
import 'package:twake_chat/domain/room_access/entities/room_access.dart';

class SaveRoomAccessUseCase {
  const SaveRoomAccessUseCase(this._roomAccessRepository);

  final RoomAccessRepository _roomAccessRepository;

  /// Throws a `RoomAccessEncryptedException` when [roomId] is encrypted and
  /// the change makes it public or listed.
  Future<void> execute(
    String roomId, {
    JoinRuleChoice? joinRule,
    bool? isListed,
  }) async {
    if ((joinRule == JoinRuleChoice.public || isListed == true) &&
        _roomAccessRepository.isEncrypted(roomId)) {
      throw const RoomAccessEncryptedException();
    }
    // The rule first: a room is never listed under a rule that was refused.
    if (joinRule != null) {
      await _roomAccessRepository.setJoinRule(roomId, joinRule);
    }
    if (isListed != null) {
      await _roomAccessRepository.setListed(roomId, isListed: isListed);
    }
  }
}

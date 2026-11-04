import 'package:twake_chat/domain/room_access/exceptions/room_access_exception.dart';
import 'package:twake_chat/domain/room_access/repositories/room_access_repository.dart';
import 'package:twake_chat/domain/room_access/entities/room_access.dart';

extension on JoinRuleChoice {
  bool get isPrivate => this != JoinRuleChoice.public;
}

class SaveRoomAccessUseCase {
  const SaveRoomAccessUseCase(this._roomAccessRepository);

  final RoomAccessRepository _roomAccessRepository;

  /// Throws a `RoomAccessEncryptedException` when [roomId] is encrypted and
  /// the change makes it public or listed, and a
  /// `RoomAccessPublicPageException` when its public page is on and the change
  /// makes it private or unlisted.
  Future<void> execute(
    String roomId, {
    JoinRuleChoice? joinRule,
    bool? isListed,
  }) async {
    _checkAllowed(roomId, joinRule: joinRule, isListed: isListed);
    // The rule first: a room is never listed under a rule that was refused.
    if (joinRule != null) {
      await _roomAccessRepository.setJoinRule(roomId, joinRule);
    }
    if (isListed != null) {
      await _roomAccessRepository.setListed(roomId, isListed: isListed);
    }
  }

  void _checkAllowed(
    String roomId, {
    required JoinRuleChoice? joinRule,
    required bool? isListed,
  }) {
    final guards = _roomAccessRepository.guardsOf(roomId);
    final opensTheRoom = joinRule == JoinRuleChoice.public || isListed == true;
    if (opensTheRoom && guards.isEncrypted) {
      throw const RoomAccessEncryptedException();
    }
    final closesTheRoom = joinRule?.isPrivate == true || isListed == false;
    if (closesTheRoom && guards.hasPublicPage) {
      throw const RoomAccessPublicPageException();
    }
  }
}

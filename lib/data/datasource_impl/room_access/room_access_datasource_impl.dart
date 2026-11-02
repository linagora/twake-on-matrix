import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/datasource/room_access/room_access_datasource.dart';
import 'package:twake_chat/domain/exception/room_access/room_access_exception.dart';
import 'package:twake_chat/domain/room_access/entities/room_access.dart';

class RoomAccessDatasourceImpl implements RoomAccessDatasource {
  const RoomAccessDatasourceImpl(this._client);

  final Client? _client;

  static const _joinRules = {
    JoinRuleChoice.invite: JoinRules.invite,
    JoinRuleChoice.knock: JoinRules.knock,
    JoinRuleChoice.public: JoinRules.public,
  };

  @override
  Future<RoomAccess> getRoomAccess(String roomId) async {
    final room = _room(roomId);
    final canChange = room.canChangeJoinRules && !room.isDirectChat;
    return RoomAccess(
      joinRule: _choiceOf(room.joinRules),
      isListed: canChange && await _isListed(roomId),
      isEncrypted: room.encrypted,
      canChange: canChange,
    );
  }

  @override
  bool isEncrypted(String roomId) => _room(roomId).encrypted;

  @override
  Future<void> setJoinRule(String roomId, JoinRuleChoice joinRule) =>
      _guard(() => _room(roomId).setJoinRules(_joinRules[joinRule]!));

  @override
  Future<void> setListed(String roomId, {required bool isListed}) => _guard(
    () => _client!.setRoomVisibilityOnDirectory(
      roomId,
      visibility: isListed ? Visibility.public : Visibility.private,
    ),
  );

  Room _room(String roomId) {
    final room = _client?.getRoomById(roomId);
    if (room == null) throw const RoomAccessRoomNotFoundException();
    return room;
  }

  JoinRuleChoice? _choiceOf(JoinRules? joinRule) => _joinRules.entries
      .where((entry) => entry.value == joinRule)
      .firstOrNull
      ?.key;

  Future<bool> _isListed(String roomId) async {
    try {
      final visibility = await _client!.getRoomVisibilityOnDirectory(roomId);
      return visibility == Visibility.public;
    } catch (e) {
      // An unreadable directory counts as not listing the room.
      Logs().w('RoomAccessDatasourceImpl::_isListed(): $e');
      return false;
    }
  }

  Future<void> _guard(Future<void> Function() change) async {
    try {
      await change();
    } on RoomAccessException {
      rethrow;
    } on MatrixException catch (e) {
      if (e.error == MatrixError.M_FORBIDDEN) {
        throw RoomAccessForbiddenException(cause: e);
      }
      throw RoomAccessSaveFailedException(cause: e);
    } catch (e) {
      throw RoomAccessSaveFailedException(cause: e);
    }
  }
}

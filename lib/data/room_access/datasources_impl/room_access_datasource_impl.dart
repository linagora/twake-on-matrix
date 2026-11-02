import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/room_access/datasources/room_access_datasource.dart';
import 'package:twake_chat/domain/room_access/entities/room_access.dart';
import 'package:twake_chat/domain/room_access/exceptions/room_access_exception.dart';

class RoomAccessDatasourceImpl implements RoomAccessDatasource {
  const RoomAccessDatasourceImpl(this._client);

  final Client? _client;

  static const _joinRules = {
    JoinRuleChoice.invite: JoinRules.invite,
    JoinRuleChoice.knock: JoinRules.knock,
    JoinRuleChoice.public: JoinRules.public,
  };

  @override
  Stream<RoomAccess> watchRoomAccess(String roomId) async* {
    final room = _room(roomId);
    var state = _stateOf(room);
    yield await _accessOf(room);
    await for (final _ in room.onUpdate.stream) {
      final next = _stateOf(room);
      if (next == state) continue;
      state = next;
      yield await _accessOf(room);
    }
  }

  @override
  bool isEncrypted(String roomId) => _room(roomId).encrypted;

  @override
  Future<void> setJoinRule(String roomId, JoinRuleChoice joinRule) =>
      _guard(() => _room(roomId).setJoinRules(_joinRules[joinRule]!));

  @override
  Future<void> setListed(String roomId, {required bool isListed}) => _guard(
    () => _room(roomId).client.setRoomVisibilityOnDirectory(
      roomId,
      visibility: isListed ? Visibility.public : Visibility.private,
    ),
  );

  Room _room(String roomId) {
    final room = _client?.getRoomById(roomId);
    if (room == null) throw const RoomAccessRoomNotFoundException();
    return room;
  }

  ({JoinRules? joinRule, bool isEncrypted, bool canChange}) _stateOf(
    Room room,
  ) => (
    joinRule: room.joinRules,
    isEncrypted: room.encrypted,
    canChange: room.canChangeJoinRules && !room.isDirectChat,
  );

  Future<RoomAccess> _accessOf(Room room) async {
    final state = _stateOf(room);
    return RoomAccess(
      joinRule: _joinRules.entries
          .where((entry) => entry.value == state.joinRule)
          .firstOrNull
          ?.key,
      isListed: state.canChange && await _isListed(room),
      isEncrypted: state.isEncrypted,
      canChange: state.canChange,
    );
  }

  Future<bool> _isListed(Room room) async {
    try {
      final visibility = await room.client.getRoomVisibilityOnDirectory(
        room.id,
      );
      return visibility == Visibility.public;
    } catch (e, s) {
      // An unreadable directory counts as not listing the room.
      Logs().w('RoomAccessDatasourceImpl::_isListed()', e, s);
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

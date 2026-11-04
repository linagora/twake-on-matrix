import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/room_access/datasources/room_access_datasource.dart';
import 'package:twake_chat/domain/room_access/entities/room_access.dart';
import 'package:twake_chat/domain/room_access/exceptions/room_access_exception.dart';

class RoomAccessDatasourceImpl implements RoomAccessDatasource {
  const RoomAccessDatasourceImpl(this._client);

  final Client? _client;

  static const _publicPageType = 'app.twake.chat.public_page';

  static const _joinRules = {
    JoinRuleChoice.invite: JoinRules.invite,
    JoinRuleChoice.knock: JoinRules.knock,
    JoinRuleChoice.public: JoinRules.public,
  };

  @override
  Stream<RoomAccess> watchRoomAccess(String roomId) async* {
    final room = _client?.getRoomById(roomId) ?? _notFound();
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
  RoomAccessGuards guardsOf(String roomId) {
    final state = _stateOf(_client?.getRoomById(roomId) ?? _notFound());
    return RoomAccessGuards(
      isEncrypted: state.isEncrypted,
      hasPublicPage: state.hasPublicPage,
    );
  }

  @override
  Future<void> setJoinRule(String roomId, JoinRuleChoice joinRule) => _guard(
    () => (_client?.getRoomById(roomId) ?? _notFound()).setJoinRules(
      _joinRules[joinRule]!,
    ),
  );

  @override
  Future<void> setListed(String roomId, {required bool isListed}) => _guard(
    () => (_client ?? _notFound()).setRoomVisibilityOnDirectory(
      roomId,
      visibility: isListed ? Visibility.public : Visibility.private,
    ),
  );

  Never _notFound() => throw const RoomAccessRoomNotFoundException();

  ({JoinRules? joinRule, bool isEncrypted, bool canChange, bool hasPublicPage})
  _stateOf(Room room) => (
    joinRule: room.joinRules,
    isEncrypted: room.encrypted,
    canChange: room.canChangeJoinRules && !room.isDirectChat,
    hasPublicPage: _hasPublicPage(room),
  );

  bool _hasPublicPage(Room room) =>
      room.getState(_publicPageType)?.content.tryGet<bool>('enabled') == true;

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
      hasPublicPage: state.hasPublicPage,
    );
  }

  Future<bool> _isListed(Room room) async {
    try {
      final visibility = await room.client.getRoomVisibilityOnDirectory(
        room.id,
      );
      return visibility == Visibility.public;
    } on Exception catch (e, s) {
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
    } on Exception catch (e, s) {
      if (_isForbidden(e)) {
        Logs().w('RoomAccessDatasourceImpl::_guard()', e, s);
        throw RoomAccessForbiddenException(cause: e);
      }
      Logs().e('RoomAccessDatasourceImpl::_guard()', e, s);
      throw RoomAccessSaveFailedException(cause: e);
    }
  }

  // Synapse, not the spec: a refused publication may be M_UNKNOWN with a 403.
  bool _isForbidden(Object error) =>
      error is MatrixException &&
      (error.error == MatrixError.M_FORBIDDEN ||
          error.response?.statusCode == 403);
}

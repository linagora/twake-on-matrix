import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/exception/spaces/space_exception.dart';

/// What a room and its space say of each other, whatever the room is.
extension SpaceRelations on Client {
  /// A parent not synced yet is checked by the server alone.
  ///
  /// Throws a [SpaceForbiddenException].
  void ensureMayAddToSpace(String parentSpaceId) {
    final parent = getRoomById(parentSpaceId);
    if (parent != null && !parent.canChangeStateEvent(EventTypes.SpaceChild)) {
      throw const SpaceForbiddenException();
    }
  }

  /// Names the space and, unless public, opens the room to its members.
  List<StateEvent> spaceParentState(
    String parentSpaceId, {
    required bool isPublic,
  }) => [
    StateEvent(
      type: EventTypes.SpaceParent,
      stateKey: parentSpaceId,
      content: {'via': viaForRoom(parentSpaceId), 'canonical': true},
    ),
    if (!isPublic)
      StateEvent(
        type: EventTypes.RoomJoinRules,
        stateKey: '',
        content: {
          'join_rule': JoinRules.restricted.name,
          'allow': [
            {'type': 'm.room_membership', 'room_id': parentSpaceId},
          ],
        },
      ),
  ];

  /// The room is of no use in a space that refuses it: it goes. Any other
  /// failure leaves the room, which names its space, and the flow goes on: the
  /// listing may have reached the server, and a space would then list a room
  /// nobody can let its members in.
  ///
  /// Throws a [SpaceForbiddenException] when the space refuses it.
  Future<void> listRoomInSpace(
    String roomId,
    String parentSpaceId, {
    bool isSuggested = false,
  }) async {
    try {
      // Not `Room.setSpaceChild`: it would overwrite the `canonical` parent.
      await setRoomStateWithKey(parentSpaceId, EventTypes.SpaceChild, roomId, {
        'via': viaForRoom(roomId),
        if (isSuggested) 'suggested': true,
      });
    } on Exception catch (exception, stackTrace) {
      if (exception is MatrixException &&
          exception.error == MatrixError.M_FORBIDDEN) {
        await _removeRoom(roomId);
        throw const SpaceForbiddenException();
      }
      Logs().w('SpaceRelations::listRoomInSpace', exception, stackTrace);
    }
  }

  /// A failure here must not hide why the room is being removed.
  Future<void> _removeRoom(String roomId) async {
    try {
      await leaveRoom(roomId);
      await forgetRoom(roomId);
    } on Exception catch (exception, stackTrace) {
      Logs().w('SpaceRelations::_removeRoom', exception, stackTrace);
    }
  }

  /// The server of a room id, then the user's: a room v12 id names none.
  List<String> viaForRoom(String roomId) => {
    // Not `String.domain`: it answers the whole id when there is no colon.
    if (roomId.contains(':')) roomId.substring(roomId.indexOf(':') + 1),
    ?userID?.domain,
  }.toList();
}

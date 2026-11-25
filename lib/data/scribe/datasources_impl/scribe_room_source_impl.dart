import 'dart:async';

import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_room.dart';
import 'package:twake_chat/domain/scribe/exceptions/scribe_exception.dart';
import 'package:twake_chat/domain/scribe/sources/scribe_room_source.dart';

/// The Scribe switch of a room, the state event Chat web writes and reads.
class ScribeRoomSourceImpl implements ScribeRoomSource {
  const ScribeRoomSourceImpl(this._client);

  final Client? _client;

  static const scribeStateType = 'app.twake.chat.scribe';

  /// Read again after every sync: whether the room is direct lives in the
  /// account data (`m.direct`), whose change brings no room update.
  @override
  Stream<ScribeRoom> watchRoom(String roomId) {
    StreamSubscription<SyncUpdate>? syncs;
    final controller = StreamController<ScribeRoom>(
      onCancel: () => syncs?.cancel(),
    );
    controller.onListen = () async {
      try {
        final room = _roomOf(roomId);
        ScribeRoom? current;
        // Listening first: a sync during the load or a pause is kept.
        syncs = room.client.onSync.stream.listen((_) {
          final next = _scribeRoomOf(room);
          if (current == null || next == current) return;
          current = next;
          controller.add(next);
        });
        // A room not opened yet holds only the important state in memory.
        await room.postLoad();
        final first = _scribeRoomOf(room);
        current = first;
        controller.add(first);
      } on Exception catch (e, s) {
        controller.addError(e, s);
      }
    };
    return controller.stream;
  }

  @override
  Future<void> setScribeEnabled(String roomId, {required bool enabled}) async {
    final room = _roomOf(roomId);
    try {
      await room.client.setRoomStateWithKey(room.id, scribeStateType, '', {
        'enabled': enabled,
      });
    } on Exception catch (e, s) {
      Logs().w('ScribeRoomSourceImpl::setScribeEnabled', e, s);
      throw const ScribeSwitchFailed();
    }
  }

  Room _roomOf(String roomId) =>
      _client?.getRoomById(roomId) ?? (throw const ScribeRoomNotFound());

  ScribeRoom _scribeRoomOf(Room room) => ScribeRoom(
    isEncrypted: room.encrypted,
    isDirect: room.isDirectChat,
    isSpace: room.isSpace,
    scribeEnabled:
        room.getState(scribeStateType)?.content.tryGet<bool>('enabled') == true,
    // Chat web's owner: may invite, at the admin level or above.
    isOwner:
        room.canInvite &&
        room.ownPowerLevel.level >= PowerLevel.defaultAdminLevel,
  );
}

import 'package:twake_chat/domain/scribe/entities/scribe_room.dart';
import 'package:twake_chat/domain/scribe/exceptions/scribe_exception.dart';

/// What a room says about the Scribe, and its owner's switch.
abstract interface class ScribeRoomSource {
  /// Emits the room now, then again each time what decides the Scribe
  /// changes (encryption, the switch, the user's power level).
  ///
  /// Throws [ScribeRoomNotFound] when the active account has no such room.
  Stream<ScribeRoom> watchRoom(String roomId);

  /// Writes the switch of the room (state `app.twake.chat.scribe`, key `''`,
  /// `{enabled}`); the new value comes back through [watchRoom] with the sync.
  ///
  /// Throws [ScribeRoomNotFound], and [ScribeSwitchFailed] when the server
  /// refuses or cannot be reached.
  Future<void> setScribeEnabled(String roomId, {required bool enabled});
}

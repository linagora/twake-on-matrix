import 'package:twake_chat/domain/scribe/entities/scribe_room.dart';
import 'package:twake_chat/domain/scribe/exceptions/scribe_exception.dart';
import 'package:twake_chat/domain/scribe/sources/scribe_room_source.dart';

/// Turns the Scribe of an encrypted group on or off, as its owner.
class SetScribeEnabledUseCase {
  const SetScribeEnabledUseCase(this._source);

  final ScribeRoomSource _source;

  /// The new value comes back with the sync, through the room.
  ///
  /// Throws [ScribeSwitchFailed] when [room] has no switch its user may flip,
  /// before writing, and the [ScribeException]s of
  /// `ScribeRoomSource.setScribeEnabled`.
  Future<void> execute({
    required String roomId,
    required ScribeRoom room,
    required bool enabled,
  }) async {
    if (!room.canChangeScribe) throw const ScribeSwitchFailed();
    await _source.setScribeEnabled(roomId, enabled: enabled);
  }
}

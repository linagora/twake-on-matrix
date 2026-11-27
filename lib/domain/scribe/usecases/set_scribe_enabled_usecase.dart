import 'package:twake_chat/domain/scribe/entities/scribe_room.dart';
import 'package:twake_chat/domain/scribe/exceptions/scribe_exception.dart';
import 'package:twake_chat/domain/scribe/sources/scribe_room_source.dart';

class SetScribeEnabledUseCase {
  const SetScribeEnabledUseCase(this._source);

  final ScribeRoomSource _source;

  Future<void> execute({
    required String roomId,
    required ScribeRoom room,
    required bool enabled,
  }) async {
    if (!room.canChangeScribe) throw const ScribeSwitchFailed();
    await _source.setScribeEnabled(roomId, enabled: enabled);
  }
}

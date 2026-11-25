import 'package:twake_chat/domain/scribe/entities/scribe_room.dart';

abstract interface class ScribeRoomSource {
  Stream<ScribeRoom> watchRoom(String roomId);

  Future<void> setScribeEnabled(String roomId, {required bool enabled});
}

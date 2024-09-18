import 'package:matrix/matrix.dart';

extension SyncUpdateExtension on SyncUpdate {
  SyncUpdate combineJoinedRoomUpdateEvents({
    SyncUpdate? other,
  }) {
    final newSyncUpdate = this;
    if (other == null || other.rooms == null) {
      return this;
    }
    if (other.rooms?.join != null) {
      for (final roomId in other.rooms!.join!.keys) {
        if (newSyncUpdate.rooms?.join?.containsKey(roomId) == true) {
          newSyncUpdate.rooms!.join![roomId]?.timeline?.events?.addAll(
            other.rooms!.join![roomId]!.timeline?.events ?? {},
          );
        } else {
          if (newSyncUpdate.rooms?.join != null &&
              other.rooms?.join?[roomId] != null) {
            newSyncUpdate.rooms!.join![roomId] = other.rooms!.join![roomId]!;
          }
        }
      }
    } else {
      newSyncUpdate.rooms?.join = other.rooms?.join;
    }
    return newSyncUpdate;
  }
}

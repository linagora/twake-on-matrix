import 'package:twake_chat/domain/model/public_rooms/public_room.dart';

abstract class PublicRoomsRepository {
  /// The directory of the user's homeserver, one page at a time, up to
  /// [limit] rooms. When a page after the first one fails, the stream ends.
  Stream<List<PublicRoom>> fetchDirectory({required int limit});

  Set<String> getJoinedRoomIds();

  /// The rooms among [roomIds] where the user's join request is pending. A
  /// room whose state cannot be read is left out.
  Future<Set<String>> getKnockedRoomIds(List<String> roomIds);

  /// Waits up to 30 seconds for the joined room to reach the sync;
  /// `isInSync` is false when it has not.
  Future<({String roomId, bool isInSync})> join(String roomIdOrAlias);

  Future<void> knock(String roomIdOrAlias);
}

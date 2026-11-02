import 'package:twake_chat/domain/model/public_rooms/public_room.dart';

abstract class PublicRoomsRepository {
  /// The directory of the user's homeserver, up to [limit] rooms. When a page
  /// after the first one fails, returns the rooms read so far.
  Future<List<PublicRoom>> fetchDirectory({required int limit});

  Set<String> getJoinedRoomIds();

  /// Returns the id of the joined room once it has reached the sync, or after
  /// 30 seconds if it has not.
  Future<String> join(String roomIdOrAlias);

  Future<void> knock(String roomIdOrAlias);
}

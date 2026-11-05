import 'package:twake_chat/domain/model/public_rooms/public_room.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room_preview.dart';

abstract class PublicRoomsRepository {
  /// The directory of the user's homeserver, one page at a time, up to
  /// [limit] rooms. When a page after the first one fails, the stream ends.
  Stream<List<PublicRoom>> fetchDirectory({required int limit});

  /// The rooms the user has joined or is invited to.
  Set<String> getKnownRoomIds();

  /// The rooms among [roomIds] where the user's join request is pending. A
  /// room whose state cannot be read is left out.
  Future<Set<String>> getKnockedRoomIds(List<String> roomIds);

  /// Waits up to 30 seconds for the joined room to reach the sync;
  /// `isInSync` is false when it has not.
  Future<({String roomId, bool isInSync})> join(
    String roomIdOrAlias, {
    List<String> via = const [],
  });

  Future<void> knock(String roomIdOrAlias, {List<String> via = const []});

  /// From the room summary, else from the directory of the room's server.
  Future<PublicRoomPreview> getPreview(
    String roomIdOrAlias, {
    required List<String> via,
  });
}

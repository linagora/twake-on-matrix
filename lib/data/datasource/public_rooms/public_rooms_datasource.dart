import 'package:twake_chat/domain/model/public_rooms/public_room.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room_preview.dart';

abstract class PublicRoomsDatasource {
  Stream<List<PublicRoom>> fetchDirectory({
    required int limit,
    String? searchTerm,
  });

  Set<String> getKnownRoomIds();

  Future<Set<String>> getKnockedRoomIds(List<String> roomIds);

  Future<({String roomId, bool isInSync})> join(
    String roomIdOrAlias, {
    List<String> via = const [],
  });

  Future<void> knock(String roomIdOrAlias, {List<String> via = const []});

  Future<PublicRoomPreview> getPreview(
    String roomIdOrAlias, {
    required List<String> via,
  });
}

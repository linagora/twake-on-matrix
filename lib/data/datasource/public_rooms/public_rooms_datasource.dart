import 'package:twake_chat/domain/model/public_rooms/public_room.dart';

abstract class PublicRoomsDatasource {
  Stream<List<PublicRoom>> fetchDirectory({required int limit});

  Set<String> getJoinedRoomIds();

  Future<Set<String>> getKnockedRoomIds(List<String> roomIds);

  Future<String> join(String roomIdOrAlias);

  Future<void> knock(String roomIdOrAlias);
}

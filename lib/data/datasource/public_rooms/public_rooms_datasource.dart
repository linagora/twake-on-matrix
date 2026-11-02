import 'package:twake_chat/domain/model/public_rooms/public_room.dart';

abstract class PublicRoomsDatasource {
  Future<List<PublicRoom>> fetchDirectory({required int limit});

  Set<String> getJoinedRoomIds();

  Future<String> join(String roomIdOrAlias);

  Future<void> knock(String roomIdOrAlias);
}

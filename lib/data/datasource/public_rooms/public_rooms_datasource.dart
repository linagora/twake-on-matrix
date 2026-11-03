import 'package:twake_chat/domain/model/public_rooms/public_room.dart';

abstract class PublicRoomsDatasource {
  Stream<List<PublicRoom>> fetchDirectory({required int limit});

  Set<String> getMemberRoomIds();

  Future<Set<String>> getKnockedRoomIds(List<String> roomIds);

  Future<({String roomId, bool isInSync})> join(String roomIdOrAlias);

  Future<void> knock(String roomIdOrAlias);
}

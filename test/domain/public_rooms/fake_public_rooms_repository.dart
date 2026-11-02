import 'dart:async';

import 'package:twake_chat/domain/exception/public_rooms/public_rooms_exception.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room.dart';
import 'package:twake_chat/domain/repository/public_rooms/public_rooms_repository.dart';

PublicRoom publicRoom(
  String id, {
  String? name,
  PublicRoomKind kind = PublicRoomKind.group,
  PublicRoomAccess access = PublicRoomAccess.open,
}) => PublicRoom(
  roomId: id,
  name: name ?? id,
  memberCount: 3,
  access: access,
  kind: kind,
);

class FakePublicRoomsRepository implements PublicRoomsRepository {
  FakePublicRoomsRepository({
    this.directory = const [],
    this.joined = const {},
    this.fetchError,
    this.joinError,
    this.knockError,
  });

  List<PublicRoom> directory;
  Set<String> joined;
  PublicRoomsException? fetchError;
  PublicRoomsException? joinError;
  PublicRoomsException? knockError;
  Completer<void>? joinGate;

  int? requestedLimit;
  final joinedIds = <String>[];
  final knockedIds = <String>[];

  @override
  Future<List<PublicRoom>> fetchDirectory({required int limit}) async {
    requestedLimit = limit;
    if (fetchError case final error?) throw error;
    return directory;
  }

  @override
  Set<String> getJoinedRoomIds() => joined;

  @override
  Future<String> join(String roomIdOrAlias) async {
    await joinGate?.future;
    if (joinError case final error?) throw error;
    joinedIds.add(roomIdOrAlias);
    return roomIdOrAlias;
  }

  @override
  Future<void> knock(String roomIdOrAlias) async {
    if (knockError case final error?) throw error;
    knockedIds.add(roomIdOrAlias);
  }
}

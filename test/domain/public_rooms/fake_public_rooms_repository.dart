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
    List<PublicRoom> directory = const [],
    List<List<PublicRoom>>? pages,
    this.joined = const {},
    this.knocked = const {},
    this.fetchError,
    this.knockedError,
    this.joinError,
    this.knockError,
  }) : pages = pages ?? [directory];

  /// Set it to emit the directory pages one by one from a test.
  StreamController<List<PublicRoom>>? directoryController;

  List<List<PublicRoom>> pages;
  Set<String> joined;
  Set<String> knocked;
  PublicRoomsException? fetchError;
  PublicRoomsException? knockedError;
  PublicRoomsException? joinError;
  PublicRoomsException? knockError;
  Completer<void>? joinGate;
  bool isJoinInSync = true;

  int? requestedLimit;
  final knockedQueries = <List<String>>[];
  final joinedIds = <String>[];
  final knockedIds = <String>[];

  @override
  Stream<List<PublicRoom>> fetchDirectory({required int limit}) {
    requestedLimit = limit;
    if (fetchError case final error?) return Stream.error(error);
    if (directoryController case final controller?) return controller.stream;
    return Stream.fromIterable(pages);
  }

  @override
  Set<String> getJoinedRoomIds() => joined;

  @override
  Future<Set<String>> getKnockedRoomIds(List<String> roomIds) async {
    knockedQueries.add(roomIds);
    if (knockedError case final error?) throw error;
    return roomIds.where(knocked.contains).toSet();
  }

  @override
  Future<({String roomId, bool isInSync})> join(String roomIdOrAlias) async {
    await joinGate?.future;
    if (joinError case final error?) throw error;
    joinedIds.add(roomIdOrAlias);
    return (roomId: roomIdOrAlias, isInSync: isJoinInSync);
  }

  @override
  Future<void> knock(String roomIdOrAlias) async {
    if (knockError case final error?) throw error;
    knockedIds.add(roomIdOrAlias);
  }
}

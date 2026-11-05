import 'dart:async';

import 'package:twake_chat/domain/exception/public_rooms/public_rooms_exception.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room_preview.dart';
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
  Object? knockedUntypedError;
  Set<String> malformedSummaryRoomIds = {};
  PublicRoomsException? joinError;
  Object? joinUntypedError;
  PublicRoomsException? knockError;
  Completer<void>? joinGate;
  Completer<void>? knockGate;
  Completer<void>? lookupGate;
  int lookupsInFlight = 0;
  int maxLookupsInFlight = 0;
  bool isJoinInSync = true;
  PublicRoomPreview preview = const PublicRoomPreview.unavailable();
  PublicRoomsException? previewError;
  final previewQueries = <String>[];
  final previewVia = <List<String>>[];
  final joinedVia = <List<String>>[];

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
  Set<String> getKnownRoomIds() => joined;

  @override
  Future<Set<String>> getKnockedRoomIds(List<String> roomIds) async {
    knockedQueries.add(roomIds);
    lookupsInFlight++;
    if (lookupsInFlight > maxLookupsInFlight) {
      maxLookupsInFlight = lookupsInFlight;
    }
    await (lookupGate?.future ?? Future<void>.delayed(Duration.zero));
    lookupsInFlight--;
    if (knockedError case final error?) throw error;
    if (knockedUntypedError case final error?) throw error;
    if (roomIds.any(malformedSummaryRoomIds.contains)) throw TypeError();
    return roomIds.where(knocked.contains).toSet();
  }

  @override
  Future<({String roomId, bool isInSync})> join(
    String roomIdOrAlias, {
    List<String> via = const [],
  }) async {
    await joinGate?.future;
    if (joinError case final error?) throw error;
    if (joinUntypedError case final error?) throw error;
    joinedIds.add(roomIdOrAlias);
    joinedVia.add(via);
    final roomId = roomIdOrAlias.startsWith('#')
        ? '!${roomIdOrAlias.substring(1)}'
        : roomIdOrAlias;
    return (roomId: roomId, isInSync: isJoinInSync);
  }

  @override
  Future<void> knock(
    String roomIdOrAlias, {
    List<String> via = const [],
  }) async {
    await knockGate?.future;
    if (knockError case final error?) throw error;
    knockedIds.add(roomIdOrAlias);
  }

  @override
  Future<PublicRoomPreview> getPreview(
    String roomIdOrAlias, {
    required List<String> via,
  }) async {
    previewQueries.add(roomIdOrAlias);
    previewVia.add(via);
    if (previewError case final error?) throw error;
    return preview;
  }
}

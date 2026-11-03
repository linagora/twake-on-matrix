import 'dart:async';

import 'package:matrix/matrix.dart';
import 'package:twake_chat/config/feed_config.dart';
import 'package:twake_chat/data/datasource/public_rooms/public_rooms_datasource.dart';
import 'package:twake_chat/domain/exception/public_rooms/public_rooms_exception.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room.dart';

class PublicRoomsDatasourceImpl implements PublicRoomsDatasource {
  const PublicRoomsDatasourceImpl(this._maybeClient);

  static const pageSize = 100;

  static const _summaryBatchSize = 5;

  static const _joinSyncTimeout = Duration(seconds: 30);

  static final _knockRules = {
    JoinRules.knock.text,
    JoinRules.knockRestricted.text,
  };

  final Client? _maybeClient;

  Client get _client =>
      _maybeClient ?? (throw const PublicRoomsNoClientException());

  @override
  Stream<List<PublicRoom>> fetchDirectory({required int limit}) async* {
    final client = _client;
    var count = 0;
    String? since;
    do {
      final QueryPublicRoomsResponse page;
      try {
        // No `server`: the directory of the user's homeserver only.
        page = await client.queryPublicRooms(limit: pageSize, since: since);
      } on Exception catch (exception, stackTrace) {
        if (count == 0) {
          Logs().e(
            'PublicRoomsDatasourceImpl::fetchDirectory',
            exception,
            stackTrace,
          );
          throw PublicRoomsFetchFailedException(cause: exception);
        }
        Logs().w(
          'PublicRoomsDatasourceImpl::fetchDirectory',
          exception,
          stackTrace,
        );
        return;
      }
      final rooms = page.chunk.take(limit - count).map(_toPublicRoom).toList();
      count += rooms.length;
      yield rooms;
      final next = page.nextBatch;
      // Defensive: the spec does not cover a server repeating the token.
      if (next != null && next == since) {
        Logs().w('PublicRoomsDatasourceImpl::fetchDirectory: token repeated');
        return;
      }
      since = next;
    } while (since != null && count < limit);
  }

  @override
  Set<String> getJoinedRoomIds() => _client.rooms
      .where((room) => room.membership == Membership.join)
      .map((room) => room.id)
      .toSet();

  @override
  Future<Set<String>> getKnockedRoomIds(List<String> roomIds) async {
    final client = _client;
    final knocked = <String>{};
    for (var start = 0; start < roomIds.length; start += _summaryBatchSize) {
      final batch = roomIds.skip(start).take(_summaryBatchSize);
      final results = await Future.wait(
        batch.map((roomId) => _isKnocked(client, roomId)),
      );
      knocked.addAll([
        for (final (index, roomId) in batch.indexed)
          if (results[index]) roomId,
      ]);
    }
    return knocked;
  }

  // The SDK ignores the rooms in the `knock` section of the sync.
  Future<bool> _isKnocked(Client client, String roomId) async {
    try {
      final summary = await client.getRoomSummary(roomId);
      return summary.membership == Membership.knock;
    } on Exception catch (exception, stackTrace) {
      Logs().w(
        'PublicRoomsDatasourceImpl::getKnockedRoomIds',
        exception,
        stackTrace,
      );
      return false;
    }
  }

  @override
  Future<String> join(String roomIdOrAlias) async {
    final client = _client;
    final String roomId;
    try {
      roomId = await client.joinRoom(roomIdOrAlias);
    } on Exception catch (exception, stackTrace) {
      Logs().e('PublicRoomsDatasourceImpl::join', exception, stackTrace);
      throw PublicRoomJoinFailedException(cause: exception);
    }
    if (client.getRoomById(roomId)?.membership == Membership.join) {
      return roomId;
    }
    try {
      await client
          .waitForRoomInSync(roomId, join: true)
          .timeout(_joinSyncTimeout);
    } on TimeoutException catch (exception) {
      // Joined on the server: opening the room still works once it syncs.
      Logs().w('PublicRoomsDatasourceImpl::join', exception);
    }
    return roomId;
  }

  @override
  Future<void> knock(String roomIdOrAlias) async {
    final client = _client;
    try {
      await client.knockRoom(roomIdOrAlias);
    } on Exception catch (exception, stackTrace) {
      Logs().e('PublicRoomsDatasourceImpl::knock', exception, stackTrace);
      throw PublicRoomKnockFailedException(cause: exception);
    }
  }

  PublicRoom _toPublicRoom(PublicRoomsChunk chunk) => PublicRoom(
    roomId: chunk.roomId,
    alias: chunk.canonicalAlias,
    name: chunk.name ?? chunk.canonicalAlias ?? chunk.roomId,
    topic: chunk.topic,
    avatarUri: chunk.avatarUrl,
    memberCount: chunk.numJoinedMembers,
    access: _knockRules.contains(chunk.joinRule)
        ? PublicRoomAccess.approval
        : PublicRoomAccess.open,
    kind: switch (chunk.roomType) {
      null => PublicRoomKind.group,
      FeedConfig.roomType => PublicRoomKind.feed,
      RoomCreationTypes.mSpace => PublicRoomKind.space,
      _ => PublicRoomKind.other,
    },
  );
}

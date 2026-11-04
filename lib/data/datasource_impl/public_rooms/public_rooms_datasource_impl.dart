import 'dart:async';

import 'package:matrix/matrix.dart';
import 'package:twake_chat/config/feed_config.dart';
import 'package:twake_chat/data/datasource/public_rooms/public_rooms_datasource.dart';
import 'package:twake_chat/domain/exception/public_rooms/public_rooms_exception.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room.dart';

class PublicRoomsDatasourceImpl implements PublicRoomsDatasource {
  const PublicRoomsDatasourceImpl(this._maybeClient);

  static const pageSize = 100;

  static const _joinSyncTimeout = Duration(seconds: 30);

  // Listed for their world-readable history, but nobody can join them.
  static final _closedRules = {JoinRules.invite.text, JoinRules.private.text};

  static const _knownMemberships = {
    Membership.join,
    Membership.invite,
    Membership.ban,
  };

  static const _maxEmptyPages = 3;

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
    var emptyPages = 0;
    var isFirstPage = true;
    String? since;
    do {
      final QueryPublicRoomsResponse page;
      try {
        // No `server`: the directory of the user's homeserver only.
        page = await client.queryPublicRooms(limit: pageSize, since: since);
      } on Exception catch (exception, stackTrace) {
        if (isFirstPage) {
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
      isFirstPage = false;
      final rooms = page.chunk
          .where((chunk) => !_closedRules.contains(chunk.joinRule))
          .take(limit - count)
          .map(_toPublicRoom)
          .toList();
      count += rooms.length;
      yield rooms;
      if (page.chunk.isEmpty && ++emptyPages == _maxEmptyPages) {
        Logs().w('PublicRoomsDatasourceImpl::fetchDirectory: empty pages');
        return;
      }
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
  Set<String> getKnownRoomIds() => _client.rooms
      .where((room) => _knownMemberships.contains(room.membership))
      .map((room) => room.id)
      .toSet();

  @override
  Future<Set<String>> getKnockedRoomIds(List<String> roomIds) async {
    final client = _client;
    final results = await Future.wait(
      roomIds.map((roomId) => _isKnocked(client, roomId)),
    );
    return {
      for (final (index, roomId) in roomIds.indexed)
        if (results[index]) roomId,
    };
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
  Future<({String roomId, bool isInSync})> join(String roomIdOrAlias) async {
    final client = _client;
    final String roomId;
    try {
      roomId = await client.joinRoom(roomIdOrAlias);
    } on Exception catch (exception, stackTrace) {
      Logs().e('PublicRoomsDatasourceImpl::join', exception, stackTrace);
      throw PublicRoomJoinFailedException(cause: exception);
    }
    if (client.getRoomById(roomId)?.membership == Membership.join) {
      return (roomId: roomId, isInSync: true);
    }
    try {
      await client
          .waitForRoomInSync(roomId, join: true)
          .timeout(_joinSyncTimeout);
    } on Exception catch (exception, stackTrace) {
      // Joined on the server either way: only the local sync is missing.
      Logs().w('PublicRoomsDatasourceImpl::join', exception, stackTrace);
      return (roomId: roomId, isInSync: false);
    }
    return (roomId: roomId, isInSync: true);
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
    name: chunk.name ?? chunk.canonicalAlias ?? chunk.roomId,
    topic: chunk.topic,
    avatarUri: chunk.avatarUrl,
    memberCount: chunk.numJoinedMembers,
    access: switch (chunk.joinRule) {
      // An absent rule means public in the directory.
      null || 'public' => PublicRoomAccess.open,
      final rule when _knockRules.contains(rule) => PublicRoomAccess.approval,
      _ => PublicRoomAccess.restricted,
    },
    kind: switch (chunk.roomType) {
      null => PublicRoomKind.group,
      FeedConfig.roomType => PublicRoomKind.feed,
      RoomCreationTypes.mSpace => PublicRoomKind.space,
      _ => PublicRoomKind.other,
    },
  );
}

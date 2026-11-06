import 'dart:async';

import 'package:matrix/matrix.dart';
import 'package:twake_chat/config/feed_config.dart';
import 'package:twake_chat/data/datasource/public_rooms/public_rooms_datasource.dart';
import 'package:twake_chat/domain/exception/public_rooms/public_rooms_exception.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room_preview.dart';

class PublicRoomsDatasourceImpl implements PublicRoomsDatasource {
  const PublicRoomsDatasourceImpl(this._maybeClient);

  static const pageSize = 100;

  static const _joinSyncTimeout = Duration(seconds: 30);

  // Listed for their world-readable history, but nobody can join them.
  static final _closedRules = {JoinRules.invite.text, JoinRules.private.text};

  static const _knownMemberships = {Membership.join, Membership.invite};

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
      final Map<String, Object?> page;
      try {
        // No `server`: the directory of the user's homeserver only.
        page = await client.request(
          RequestType.GET,
          '/client/v3/publicRooms',
          query: {'limit': '$pageSize', 'since': ?since},
        );
        if (page['chunk'] is! List) {
          throw const FormatException('publicRooms: no chunk list');
        }
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
      final rooms = _parseChunks(page['chunk'] as List)
          .where((chunk) => !_closedRules.contains(chunk.joinRule))
          .take(limit - count)
          .map(_toPublicRoom)
          .toList();
      count += rooms.length;
      yield rooms;
      if (rooms.isEmpty && ++emptyPages == _maxEmptyPages) {
        Logs().w('PublicRoomsDatasourceImpl::fetchDirectory: empty pages');
        return;
      }
      final next = page['next_batch'] as String?;
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
  Future<({String roomId, bool isInSync})> join(
    String roomIdOrAlias, {
    List<String> via = const [],
  }) async {
    final client = _client;
    final String roomId;
    try {
      roomId = await client.joinRoom(
        roomIdOrAlias,
        via: via.isEmpty ? null : via,
      );
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
  Future<void> knock(
    String roomIdOrAlias, {
    List<String> via = const [],
  }) async {
    final client = _client;
    try {
      await client.knockRoom(roomIdOrAlias, via: via.isEmpty ? null : via);
    } on Exception catch (exception, stackTrace) {
      Logs().e('PublicRoomsDatasourceImpl::knock', exception, stackTrace);
      throw PublicRoomKnockFailedException(cause: exception);
    }
  }

  @override
  Future<PublicRoomPreview> getPreview(
    String roomIdOrAlias, {
    required List<String> via,
  }) async {
    final client = _client;
    final localRoom =
        client.getRoomByAlias(roomIdOrAlias) ??
        client.getRoomById(roomIdOrAlias);
    // The SDK keeps a room the user was banned from as left; after a restart
    // the member event is only in the database.
    final ownMember = await localRoom?.requestUser(
      client.userID!,
      requestState: false,
      requestProfile: false,
    );
    if (ownMember?.membership == Membership.ban) {
      return const PublicRoomPreview.banned();
    }
    final summary = await _fetchSummary(client, roomIdOrAlias, via);
    if (summary == null) return const PublicRoomPreview.unavailable();
    return switch (summary.membership) {
      Membership.join ||
      Membership.invite => PublicRoomPreview.joined(summary.roomId),
      Membership.ban => const PublicRoomPreview.banned(),
      _ when _closedRules.contains(summary.joinRule) =>
        const PublicRoomPreview.unavailable(),
      final membership => PublicRoomPreview.found(
        _toPublicRoom(summary),
        isRequested: membership == Membership.knock,
      ),
    };
  }

  // https://spec.matrix.org/v1.16/client-server-api/#get_matrixclientv1room_summaryroomidoralias
  Future<GetRoomSummaryResponse$3?> _fetchSummary(
    Client client,
    String roomIdOrAlias,
    List<String> via,
  ) async {
    try {
      return await client.getRoomSummary(
        roomIdOrAlias,
        via: via.isEmpty ? null : via,
      );
    } on Exception catch (exception, stackTrace) {
      Logs().w('PublicRoomsDatasourceImpl::getPreview', exception, stackTrace);
      return null;
    }
  }

  // Parsed one by one: the SDK parses the whole page, so one room with a
  // malformed field (an invalid avatar URL) would drop all the others.
  List<PublicRoomsChunk> _parseChunks(List chunks) => [
    for (final json in chunks)
      if (_parseChunk(json) case final chunk?) chunk,
  ];

  PublicRoomsChunk? _parseChunk(Object? json) {
    try {
      return PublicRoomsChunk.fromJson(json as Map<String, Object?>);
    } on Object catch (error, stackTrace) {
      Logs().w('PublicRoomsDatasourceImpl: skipped a room', error, stackTrace);
      return null;
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

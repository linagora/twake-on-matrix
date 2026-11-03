import 'dart:async';

import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/datasource/spaces/space_datasource.dart';
import 'package:twake_chat/data/datasource_impl/spaces/room_list_entry_mapper.dart';
import 'package:twake_chat/data/datasource_impl/spaces/space_relations.dart';
import 'package:twake_chat/domain/exception/spaces/space_exception.dart';
import 'package:twake_chat/domain/spaces/new_space.dart';
import 'package:twake_chat/domain/spaces/room_list_entry.dart';
import 'package:twake_chat/domain/spaces/space_models.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/client_room_list_extension.dart';
import 'package:twake_chat/utils/stream_extension.dart';

class SpaceDatasourceImpl implements SpaceDatasource {
  const SpaceDatasourceImpl(this._activeClient);

  /// One page: the home shows the first channels, as the React client.
  static const int _hierarchyLimit = 100;

  /// The rooms of a Twake Space space, whose members are managed over there.
  static const String _managedAliasPrefix = '#twake-space-';

  static const Duration _changesRate = Duration(seconds: 1);

  /// What `order` may hold, by the Matrix spec.
  static final RegExp _validOrder = RegExp(r'^[\x20-\x7E]{1,50}$');

  final Client? _activeClient;

  Client get _client =>
      _activeClient ?? (throw StateError('No active Matrix client'));

  bool _isJoinableRule(String? rule) =>
      rule == JoinRules.public.name || rule == JoinRules.restricted.name;

  @override
  Stream<int> watchRoomChanges() async* {
    final client = _activeClient;
    if (client == null) return;
    var tick = 0;
    // An account other than the first reads its rooms after the first frame.
    await client.roomsLoading;
    yield ++tick;
    yield* client.onSync.stream
        // What entries read: not a to-device event.
        .where(
          (update) =>
              (update.accountData?.isNotEmpty ?? false) ||
              (update.rooms?.join?.isNotEmpty ?? false) ||
              (update.rooms?.invite?.isNotEmpty ?? false) ||
              (update.rooms?.leave?.isNotEmpty ?? false),
        )
        .rateLimit(_changesRate)
        .map((_) => ++tick);
  }

  @override
  List<RoomListEntry> getRoomListEntries() {
    final client = _activeClient;
    return client == null
        ? const []
        : roomListEntriesOf(
            client.listedRooms,
            directChats: client.directChats,
          );
  }

  @override
  SpaceSummary? getSpace(String roomId) {
    final room = _activeClient?.getRoomById(roomId);
    if (room == null) return null;
    return _isJoinedSpace(room) ? _summaryOf(room) : null;
  }

  bool _isJoinedSpace(Room room) =>
      room.isSpace && room.membership == Membership.join;

  SpaceSummary _summaryOf(Room room) => SpaceSummary(
    id: room.id,
    name: room.getLocalizedDisplayname(),
    memberCount: room.summary.mJoinedMemberCount ?? 0,
    isPublic: room.joinRules == JoinRules.public,
    canInvite:
        room.canInvite && !room.canonicalAlias.startsWith(_managedAliasPrefix),
    canAddChildren: room.canChangeStateEvent(EventTypes.SpaceChild),
    avatar: room.avatar,
    topic: room.topic,
  );

  @override
  List<SpaceSummary> getAddableSpaces() {
    final client = _activeClient;
    if (client == null) return const [];
    return [
      for (final room in client.listedRooms)
        if (_isJoinedSpace(room) &&
            room.canChangeStateEvent(EventTypes.SpaceChild))
          _summaryOf(room),
    ];
  }

  @override
  Future<List<SpaceChannel>> getSpaceChildren(String spaceId) async {
    try {
      final response = await _client.getSpaceHierarchy(
        spaceId,
        limit: _hierarchyLimit,
        maxDepth: 1,
      );
      final relations = {
        for (final room in response.rooms)
          if (room.roomId == spaceId)
            for (final event in room.childrenState) event.stateKey: event,
      };
      return orderSpaceChildren(
        response.rooms.where((room) => room.roomId != spaceId).map((room) {
          final relation = relations[room.roomId];
          final order = relation?.content.tryGet<String>('order');
          return SpaceChannel(
            roomId: room.roomId,
            name: room.name ?? room.canonicalAlias ?? room.roomId,
            avatar: room.avatarUrl,
            memberCount: room.numJoinedMembers,
            isSpace: room.roomType == RoomCreationTypes.mSpace,
            isJoined:
                _client.getRoomById(room.roomId)?.membership == Membership.join,
            isJoinable: _isJoinableRule(room.joinRule),
            via: relation?.content.tryGetList<String>('via') ?? const [],
            order: order != null && _validOrder.hasMatch(order) ? order : null,
            listedAt: relation?.originServerTs.millisecondsSinceEpoch,
          );
        }).toList(),
      );
    } on Exception catch (exception, stackTrace) {
      Logs().w('SpaceDatasourceImpl::getSpaceChildren', exception, stackTrace);
      throw const SpaceChildrenUnavailableException();
    }
  }

  @override
  Future<void> joinRoom(String roomId, {List<String> via = const []}) async {
    try {
      await _client.joinRoom(
        roomId,
        via: via.isEmpty ? _client.viaForRoom(roomId) : via,
      );
      if (_client.getRoomById(roomId)?.membership != Membership.join) {
        await _client.waitForRoomInSync(roomId, join: true);
      }
    } on Exception catch (exception, stackTrace) {
      Logs().w('SpaceDatasourceImpl::joinRoom', exception, stackTrace);
      throw const SpaceJoinFailedException();
    }
  }

  @override
  Future<void> open(String roomId) async {
    final room = _activeClient?.getRoomById(roomId);
    if (room == null) return;
    try {
      // The topic and the join rules are not loaded for the room list.
      await room.postLoad();
      final last = room.lastEvent;
      if (last != null && room.isUnread) {
        await room.setReadMarker(last.eventId, mRead: last.eventId);
      }
    } on Exception catch (exception, stackTrace) {
      // The home stands without it.
      Logs().w('SpaceDatasourceImpl::open', exception, stackTrace);
    }
  }

  @override
  Future<String> createSpace(NewSpace space) async {
    final parentId = space.parentSpaceId;
    if (parentId != null) _client.ensureMayAddToSpace(parentId);
    try {
      final roomId = await _createSpaceRoom(space);
      if (parentId != null) await _client.listRoomInSpace(roomId, parentId);
      // Opening the room fails if it has not reached the sync yet.
      if (_client.getRoomById(roomId) == null) {
        await _client.waitForRoomInSync(roomId, join: true);
      }
      return roomId;
    } on SpaceException {
      rethrow;
    } on Exception catch (exception, stackTrace) {
      Logs().e('SpaceDatasourceImpl::createSpace', exception, stackTrace);
      throw _isForbidden(exception)
          ? const SpaceForbiddenException()
          : const SpaceCreationFailedException();
    }
  }

  bool _isForbidden(Exception exception) =>
      exception is MatrixException &&
      exception.error == MatrixError.M_FORBIDDEN;

  Future<String> _createSpaceRoom(NewSpace space) => _client.createRoom(
    name: space.name,
    topic: space.topic.isEmpty ? null : space.topic,
    preset: space.isPublic
        ? CreateRoomPreset.publicChat
        : CreateRoomPreset.privateChat,
    visibility: space.isPublic ? Visibility.public : null,
    creationContent: {
      'type': RoomCreationTypes.mSpace,
      if (space.isPublic && space.isServerLimited) 'm.federate': false,
    },
    initialState: _initialStateOf(space),
  );

  List<StateEvent> _initialStateOf(NewSpace space) => [
    if (space.urlAvatar case final url?)
      StateEvent(
        type: EventTypes.RoomAvatar,
        stateKey: '',
        content: {'url': url},
      ),
    if (space.parentSpaceId case final parentId?)
      ..._client.spaceParentState(parentId, isPublic: space.isPublic),
  ];
}

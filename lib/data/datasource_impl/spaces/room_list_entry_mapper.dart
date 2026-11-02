import 'package:matrix/matrix.dart';
import 'package:twake_chat/config/feed_config.dart';
import 'package:twake_chat/domain/spaces/room_list_entry.dart';

/// The prefix of the `m.tag` of a chat picked for a folder.
const String folderTagPrefix = 'u.';

final RegExp _botId = RegExp(r'^@(bot_|hermes_)');

/// A room's spaces: every joined space listing it, then the joined spaces it
/// names, so a new room shows under its space before the space lists it.
List<RoomListEntry> roomListEntriesOf(
  List<Room> rooms, {
  required Map<String, List<String>> directChats,
}) {
  // `Room.directChatMatrixID` rebuilds `Client.directChats` at each call.
  // As in the SDK, the first user listing a room decides, valid or not.
  final directByRoom = <String, String>{};
  for (final chat in directChats.entries) {
    for (final roomId in chat.value) {
      directByRoom.putIfAbsent(roomId, () => chat.key);
    }
  }
  directByRoom.removeWhere((_, userId) => !userId.isValidMatrixIdStrict());
  final spaces = rooms.where((room) => room.isSpace).toList();
  final joinedSpaceIds = {
    for (final space in spaces)
      if (space.membership == Membership.join) space.id,
  };
  final childIdsOf = {
    for (final space in spaces)
      space.id: space.spaceChildren
          .map((child) => child.roomId)
          .whereType<String>()
          .toList(),
  };
  final listedBy = <String, List<String>>{};
  // By id, so the first space does not move with the order of `client.rooms`.
  for (final spaceId in joinedSpaceIds.toList()..sort()) {
    for (final childId in childIdsOf[spaceId]!) {
      (listedBy[childId] ??= []).add(spaceId);
    }
  }
  return [
    for (final room in rooms)
      _entryOf(
        room,
        directId: _directIdOf(room, directByRoom),
        childIds: childIdsOf[room.id] ?? const [],
        parentSpaceIds: {
          ...?listedBy[room.id],
          ...room.spaceParents
              .map((parent) => parent.roomId)
              .where(joinedSpaceIds.contains)
              .whereType<String>(),
        }.toList(),
      ),
  ];
}

RoomListEntry _entryOf(
  Room room, {
  required String? directId,
  required List<String> childIds,
  required List<String> parentSpaceIds,
}) => RoomListEntry(
  id: room.id,
  name: _nameOf(room, directId),
  avatar: room.avatar,
  kind: _kindOf(room, directId),
  isJoined: room.membership == Membership.join,
  canAddChildren:
      room.isSpace && room.canChangeStateEvent(EventTypes.SpaceChild),
  isFavourite: room.isFavourite,
  isMarkedUnread: room.markedUnread || room.membership == Membership.invite,
  unreadCount: room.notificationCount,
  mentionCount: room.highlightCount,
  parentSpaceIds: parentSpaceIds,
  childIds: childIds,
  folders: [
    for (final tag in room.tags.keys)
      if (tag.startsWith(folderTagPrefix) &&
          tag.length > folderTagPrefix.length)
        tag.substring(folderTagPrefix.length),
  ],
);

/// An invitation names its sender, which only the room can tell.
String? _directIdOf(Room room, Map<String, String> directByRoom) =>
    room.membership == Membership.invite
    ? room.directChatMatrixID
    : directByRoom[room.id];

/// The name `Room.getLocalizedDisplayname` gives to a DM with no name: it asks
/// the SDK three times who the partner is, each time rebuilding `directChats`.
String _nameOf(Room room, String? directId) {
  if (directId == null ||
      room.membership != Membership.join ||
      room.name.isNotEmpty ||
      (room.canonicalAlias.localpart?.isNotEmpty ?? false)) {
    return room.getLocalizedDisplayname();
  }
  final heroes = room.summary.mHeroes ?? [directId];
  final name = (heroes.isEmpty ? [directId] : heroes)
      .where((hero) => hero.isNotEmpty && hero != room.client.userID)
      .map(
        (hero) =>
            room.unsafeGetUserFromMemoryOrFallback(hero).calcDisplayname(),
      )
      .join(', ');
  final partner = room.unsafeGetUserFromMemoryOrFallback(directId);
  final isAbandoned =
      partner.membership == Membership.leave &&
      room.summary.mJoinedMemberCount == 1 &&
      room.summary.mInvitedMemberCount == 0;
  return isAbandoned
      ? const MatrixDefaultLocalizations().wasDirectChatDisplayName(name)
      : name;
}

RoomKind _kindOf(Room room, String? directId) {
  if (room.isSpace) return RoomKind.space;
  if (directId != null) {
    return _botId.hasMatch(directId) ? RoomKind.bot : RoomKind.direct;
  }
  return _isBroadcast(room) ? RoomKind.broadcast : RoomKind.group;
}

/// A feed, or a room where a member of the default level may not post.
bool _isBroadcast(Room room) {
  final createType = room
      .getState(EventTypes.RoomCreate)
      ?.content
      .tryGet<String>('type');
  if (createType == FeedConfig.roomType) return true;
  final levels = room.getState(EventTypes.RoomPowerLevels)?.content;
  final postLevel =
      levels
          ?.tryGetMap<String, Object?>('events')
          ?.tryGet<int>(EventTypes.Message) ??
      levels?.tryGet<int>('events_default') ??
      0;
  final memberLevel = levels?.tryGet<int>('users_default') ?? 0;
  return postLevel > memberLevel;
}

import 'package:twake_chat/domain/spaces/room_list_entry.dart';
import 'package:twake_chat/domain/spaces/space_models.dart';
import 'package:twake_chat/domain/spaces/space_tree.dart';

/// A space and what it holds: nothing to fold, shown or hidden.
enum SpaceFold { none, open, folded }

/// One line of the room list.
sealed class RoomListRow {
  const RoomListRow({required this.key, required this.depth});

  final String key;
  final int depth;
}

/// A room of the user. A pinned channel shows twice: on top and in its space.
class RoomListRoomRow extends RoomListRow {
  const RoomListRoomRow(this.entry, {required super.key, super.depth = 0});

  final RoomListEntry entry;
}

/// A space of the user, with what it counts: a folded one adds the rooms under
/// it.
class RoomListSpaceRow extends RoomListRow {
  const RoomListSpaceRow(
    this.entry, {
    required super.key,
    required super.depth,
    required this.fold,
    required this.unreadCount,
    required this.mentionCount,
  });

  final RoomListEntry entry;
  final SpaceFold fold;
  final int unreadCount;
  final int mentionCount;
}

/// A sub-space the user may join, under its space.
class RoomListJoinableRow extends RoomListRow {
  RoomListJoinableRow(
    this.subspace, {
    required this.parentSpaceId,
    required super.depth,
  }) : super(key: 'joinable:$parentSpaceId:${subspace.roomId}');

  final SpaceChannel subspace;
  final String parentSpaceId;
}

/// The list as it shows: the pinned rooms, then every room by its place in
/// [visible], each space with its rooms under it, at the place of its most
/// recent room.
List<RoomListRow> buildRoomListRows(
  List<RoomListEntry> visible, {
  Set<String> foldedSpaceIds = const {},
  Map<String, List<SpaceChannel>> joinableBySpace = const {},
}) {
  final byId = {for (final entry in visible) entry.id: entry};
  final indexOf = {
    for (final (index, entry) in visible.indexed) entry.id: index,
  };
  List<RoomListRow> spaceRows(SpaceNode node) =>
      _spaceRows(node, 0, foldedSpaceIds, joinableBySpace);
  // A pinned room stays in its space: the space keeps all its channels.
  final arranged = arrangeRooms([
    for (final entry in visible)
      if (!entry.isFavourite ||
          entry.isSpace ||
          parentSpaceOf(entry, byId) != null)
        entry,
  ]);

  final pinned = <RoomListRow>[
    for (final entry in visible)
      if (entry.isFavourite && !entry.isSpace)
        RoomListRoomRow(entry, key: 'pinned:${entry.id}'),
    for (final node in arranged.spaces)
      if (node.entry.isFavourite) ...spaceRows(node),
  ];

  int placeOf(SpaceNode node) => [
    node.entry,
    ...node.descendants,
  ].map((entry) => indexOf[entry.id]!).reduce((a, b) => a < b ? a : b);

  final placed = <(int, List<RoomListRow>)>[
    for (final node in arranged.spaces)
      if (!node.entry.isFavourite) (placeOf(node), spaceRows(node)),
    for (final entry in [...arranged.channels, ...arranged.directs])
      if (!entry.isFavourite)
        (indexOf[entry.id]!, [RoomListRoomRow(entry, key: entry.id)]),
  ]..sort((a, b) => a.$1.compareTo(b.$1));

  return [...pinned, ...placed.expand((item) => item.$2)];
}

List<RoomListRow> _spaceRows(
  SpaceNode node,
  int depth,
  Set<String> foldedSpaceIds,
  Map<String, List<SpaceChannel>> joinableBySpace,
) {
  // What the space listed a moment ago may be joined by now.
  final held = {for (final child in node.children) child.entry.id};
  final joinable = (joinableBySpace[node.entry.id] ?? const <SpaceChannel>[])
      .where((subspace) => !held.contains(subspace.roomId))
      .toList();
  final canFold = node.children.isNotEmpty || joinable.isNotEmpty;
  final isOpen = !foldedSpaceIds.contains(node.entry.id);
  // A pinned channel has its own badge on top: it is not counted twice.
  final counted = isOpen
      ? [node.entry]
      : [
          node.entry,
          ...node.descendants.where((e) => e.isSpace || !e.isFavourite),
        ];
  return [
    RoomListSpaceRow(
      node.entry,
      key: node.entry.id,
      depth: depth,
      fold: !canFold
          ? SpaceFold.none
          : isOpen
          ? SpaceFold.open
          : SpaceFold.folded,
      unreadCount: counted.fold(0, (sum, e) => sum + e.unreadCount),
      mentionCount: counted.fold(0, (sum, e) => sum + e.mentionCount),
    ),
    if (isOpen) ...[
      for (final child in node.children)
        if (child.entry.isSpace)
          ..._spaceRows(child, depth + 1, foldedSpaceIds, joinableBySpace)
        else
          RoomListRoomRow(child.entry, key: child.entry.id, depth: depth + 1),
      for (final subspace in joinable)
        RoomListJoinableRow(
          subspace,
          parentSpaceId: node.entry.id,
          depth: depth + 1,
        ),
    ],
  ];
}

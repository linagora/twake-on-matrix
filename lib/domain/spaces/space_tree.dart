import 'package:collection/collection.dart';
import 'package:twake_chat/domain/spaces/room_list_entry.dart';

/// A space of the list with what it holds: its channels and sub-spaces.
class SpaceNode {
  const SpaceNode(this.entry, this.children);

  final RoomListEntry entry;
  final List<SpaceNode> children;

  Iterable<RoomListEntry> get descendants =>
      children.expand((child) => [child.entry, ...child.descendants]);
}

class ArrangedRooms {
  const ArrangedRooms({
    required this.spaces,
    required this.channels,
    required this.directs,
  });

  /// The spaces in no other space of the list, each with its tree.
  final List<SpaceNode> spaces;

  /// The group rooms in no space of the list.
  final List<RoomListEntry> channels;
  final List<RoomListEntry> directs;
}

/// The first space of [byId] that holds [entry]: a room in two spaces goes
/// under the first one it names.
RoomListEntry? parentSpaceOf(
  RoomListEntry entry,
  Map<String, RoomListEntry> byId,
) => entry.parentSpaceIds
    .where((id) => id != entry.id)
    .map((id) => byId[id])
    .firstWhereOrNull((parent) => parent?.isSpace == true);

/// Each channel and sub-space under its space, what has no space of the list
/// on its own. The order of [entries] is kept at every level.
ArrangedRooms arrangeRooms(List<RoomListEntry> entries) {
  final byId = {for (final entry in entries) entry.id: entry};

  bool isTop(RoomListEntry entry) =>
      !entry.isDirect && parentSpaceOf(entry, byId) == null;

  final childrenOf = <String, List<RoomListEntry>>{};
  for (final entry in entries.where((entry) => !entry.isDirect)) {
    final parent = parentSpaceOf(entry, byId);
    if (parent != null) (childrenOf[parent.id] ??= []).add(entry);
  }

  // A space listed in its own descendants (a loop) is shown once.
  final placed = <String>{};
  SpaceNode grow(RoomListEntry entry) {
    placed.add(entry.id);
    return SpaceNode(entry, [
      for (final child in childrenOf[entry.id] ?? const <RoomListEntry>[])
        if (!placed.contains(child.id)) grow(child),
    ]);
  }

  final spaces = [
    for (final entry in entries)
      if (entry.isSpace && isTop(entry)) grow(entry),
  ];
  // Spaces that only hold each other: start from one of them.
  for (final entry in entries.where((entry) => entry.isSpace)) {
    if (!placed.contains(entry.id)) spaces.add(grow(entry));
  }

  return ArrangedRooms(
    spaces: spaces,
    channels: entries.where((e) => !e.isSpace && isTop(e)).toList(),
    directs: entries.where((e) => e.isDirect).toList(),
  );
}

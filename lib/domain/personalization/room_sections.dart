import 'package:twake_chat/domain/personalization/display_preferences.dart';
import 'package:twake_chat/domain/spaces/room_list_entry.dart';

/// The sections of the order « sections ».
enum RoomSectionKind { unread, spaces, groups, directs }

/// The order the sections show in, as in the web app: unread, spaces,
/// groups, then direct chats.
const List<RoomSectionKind> roomSectionOrder = [
  RoomSectionKind.unread,
  RoomSectionKind.spaces,
  RoomSectionKind.groups,
  RoomSectionKind.directs,
];

/// Rooms under one title; no title in the order « recent ».
class RoomSection {
  const RoomSection(this.kind, this.entries);

  final RoomSectionKind? kind;
  final List<RoomListEntry> entries;
}

/// [rooms] (newest first) as the chat list shows them in [order]. A room is
/// in one section only, each section keeps the order of [rooms] and an empty
/// section is left out.
List<RoomSection> roomSections(List<RoomListEntry> rooms, RoomOrder order) {
  if (order == RoomOrder.recent) return [RoomSection(null, rooms)];
  final byKind = {for (final kind in roomSectionOrder) kind: <RoomListEntry>[]};
  for (final room in rooms) {
    byKind[_kindOf(room)]!.add(room);
  }
  return [
    for (final MapEntry(:key, :value) in byKind.entries)
      if (value.isNotEmpty) RoomSection(key, value),
  ];
}

// A space counts what it holds: it stays a space, read or not.
RoomSectionKind _kindOf(RoomListEntry room) => room.isSpace
    ? RoomSectionKind.spaces
    : room.isUnread
    ? RoomSectionKind.unread
    : room.isDirect
    ? RoomSectionKind.directs
    : RoomSectionKind.groups;

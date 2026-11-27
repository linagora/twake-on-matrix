import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/personalization/display_preferences.dart';
import 'package:twake_chat/domain/personalization/room_sections.dart';
import 'package:twake_chat/domain/spaces/room_list_entry.dart';

/// The rooms as the list receives them: newest first.
const _rooms = [
  RoomListEntry(id: 'alice', kind: RoomKind.direct, unreadCount: 2),
  RoomListEntry(id: 'team', kind: RoomKind.group),
  RoomListEntry(id: 'bob', kind: RoomKind.direct),
  RoomListEntry(id: 'design', kind: RoomKind.group, mentionCount: 1),
  RoomListEntry(id: 'bot', kind: RoomKind.bot),
  RoomListEntry(id: 'ops', kind: RoomKind.group),
  RoomListEntry(id: 'carol', kind: RoomKind.direct, isMarkedUnread: true),
];

/// Each section as its title and the ids of its rooms, in order. The ids are
/// joined so that a record compares by content, not by list identity.
List<(RoomSectionKind?, String)> _shape(List<RoomSection> sections) => [
  for (final section in sections)
    (section.kind, [for (final entry in section.entries) entry.id].join(',')),
];

void main() {
  group('the room order « sections »', () {
    test('unread rooms first, then groups, then direct chats, each newest '
        'first', () {
      expect(_shape(roomSections(_rooms, RoomOrder.sections)), [
        (RoomSectionKind.unread, 'alice,design,carol'),
        (RoomSectionKind.groups, 'team,ops'),
        (RoomSectionKind.directs, 'bob,bot'),
      ]);
    });

    test('spaces come between the unread rooms and the groups', () {
      const withSpaces = [
        RoomListEntry(id: 'team', kind: RoomKind.group),
        RoomListEntry(id: 'linagora', kind: RoomKind.space),
        RoomListEntry(id: 'alice', kind: RoomKind.direct, unreadCount: 2),
        RoomListEntry(id: 'bob', kind: RoomKind.direct),
        RoomListEntry(id: 'design', kind: RoomKind.space),
      ];

      expect(_shape(roomSections(withSpaces, RoomOrder.sections)), [
        (RoomSectionKind.unread, 'alice'),
        (RoomSectionKind.spaces, 'linagora,design'),
        (RoomSectionKind.groups, 'team'),
        (RoomSectionKind.directs, 'bob'),
      ]);
    });

    test('an unread room is listed once, under « unread » only', () {
      final ids = [
        for (final section in roomSections(_rooms, RoomOrder.sections))
          ...section.entries.map((entry) => entry.id),
      ];

      expect(ids, unorderedEquals(_rooms.map((entry) => entry.id)));
      expect(ids.length, _rooms.length);
    });

    test('a section with no room is not listed', () {
      const groupsOnly = [
        RoomListEntry(id: 'team', kind: RoomKind.group),
        RoomListEntry(id: 'ops', kind: RoomKind.group),
      ];

      expect(_shape(roomSections(groupsOnly, RoomOrder.sections)), [
        (RoomSectionKind.groups, 'team,ops'),
      ]);
    });

    test('nothing unread: no « unread » section', () {
      final read = [
        for (final entry in _rooms)
          entry.copyWith(
            unreadCount: 0,
            mentionCount: 0,
            isMarkedUnread: false,
          ),
      ];

      expect(
        roomSections(read, RoomOrder.sections).map((section) => section.kind),
        [RoomSectionKind.groups, RoomSectionKind.directs],
      );
    });

    test('no room: no section', () {
      expect(roomSections(const [], RoomOrder.sections), isEmpty);
    });
  });

  group('the room order « recent »', () {
    test('keeps every room newest first, under no title', () {
      expect(_shape(roomSections(_rooms, RoomOrder.recent)), [
        (null, [for (final entry in _rooms) entry.id].join(',')),
      ]);
    });
  });
}

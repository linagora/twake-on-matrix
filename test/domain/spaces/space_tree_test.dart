import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/spaces/room_list_entry.dart';
import 'package:twake_chat/domain/spaces/space_tree.dart';

RoomListEntry _space(String id, {List<String> parents = const []}) =>
    RoomListEntry(id: id, kind: RoomKind.space, parentSpaceIds: parents);

RoomListEntry _room(String id, {List<String> parents = const []}) =>
    RoomListEntry(id: id, parentSpaceIds: parents);

List<String> _ids(List<SpaceNode> nodes) =>
    nodes.map((node) => node.entry.id).toList();

void main() {
  group('arrangeRooms', () {
    test('whenChannelHasSpace_putsItUnderInListOrder', () {
      final arranged = arrangeRooms([
        _room('!b', parents: ['!s']),
        _space('!s'),
        _room('!a', parents: ['!s']),
        _room('!loose'),
      ]);

      expect(_ids(arranged.spaces), ['!s']);
      expect(_ids(arranged.spaces.single.children), ['!b', '!a']);
      expect(arranged.channels.map((entry) => entry.id), ['!loose']);
    });

    test('whenSubSpaceHasChannels_nestsThem', () {
      final arranged = arrangeRooms([
        _space('!s'),
        _space('!sub', parents: ['!s']),
        _room('!c', parents: ['!sub']),
      ]);

      final sub = arranged.spaces.single.children.single;
      expect(sub.entry.id, '!sub');
      expect(_ids(sub.children), ['!c']);
    });

    test('whenSpaceIsNotInList_leavesRoomOnItsOwn', () {
      final arranged = arrangeRooms([
        _room('!c', parents: ['!unknown']),
      ]);

      expect(arranged.spaces, isEmpty);
      expect(arranged.channels.map((entry) => entry.id), ['!c']);
    });

    test('whenRoomIsInTwoSpaces_putsItUnderTheFirstNamed', () {
      final arranged = arrangeRooms([
        _space('!one'),
        _space('!two'),
        _room('!c', parents: ['!two', '!one']),
      ]);

      final byId = {for (final node in arranged.spaces) node.entry.id: node};
      expect(_ids(byId['!two']!.children), ['!c']);
      expect(byId['!one']!.children, isEmpty);
    });

    test('whenDirectChatNamesSpace_neverNestsIt', () {
      final arranged = arrangeRooms([
        _space('!s'),
        const RoomListEntry(
          id: '!dm',
          kind: RoomKind.direct,
          parentSpaceIds: ['!s'],
        ),
      ]);

      expect(arranged.spaces.single.children, isEmpty);
      expect(arranged.directs.map((entry) => entry.id), ['!dm']);
    });

    test('whenSpacesHoldEachOther_showsEachOnce', () {
      final arranged = arrangeRooms([
        _space('!a', parents: ['!b']),
        _space('!b', parents: ['!a']),
      ]);

      expect(_ids(arranged.spaces), ['!a']);
      expect(_ids(arranged.spaces.single.children), ['!b']);
      expect(arranged.spaces.single.children.single.children, isEmpty);
    });

    test('whenSpaceNamesItself_staysAtTheTop', () {
      final arranged = arrangeRooms([
        _space('!s', parents: ['!s']),
      ]);

      expect(_ids(arranged.spaces), ['!s']);
      expect(arranged.spaces.single.children, isEmpty);
    });
  });

  group('parentSpaceOf', () {
    test('whenFirstNamedIsNoSpace_skipsIt', () {
      final byId = {'!room': _room('!room'), '!s': _space('!s')};

      expect(
        parentSpaceOf(_room('!c', parents: ['!room', '!s']), byId)?.id,
        '!s',
      );
    });

    test('whenRoomNamesItself_ignoresIt', () {
      final entry = _space('!s', parents: ['!s']);

      expect(parentSpaceOf(entry, {'!s': entry}), isNull);
    });
  });
}

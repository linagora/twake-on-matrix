import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/spaces/space_models.dart';

void main() {
  group('orderSpaceChildren', () {
    test('whenOrdersAreGiven_putsThemFirstByCodePoint', () {
      final ordered = orderSpaceChildren(const [
        SpaceChannel(roomId: '!none', name: '', listedAt: 1),
        SpaceChannel(roomId: '!b', name: '', order: 'b', listedAt: 9),
        SpaceChannel(roomId: '!a', name: '', order: 'a', listedAt: 8),
      ]);

      expect(ordered.map((c) => c.roomId), ['!a', '!b', '!none']);
    });

    test('whenNoOrder_sortsByTimeThenRoomId', () {
      final ordered = orderSpaceChildren(const [
        SpaceChannel(roomId: '!unknown', name: ''),
        SpaceChannel(roomId: '!z', name: '', listedAt: 1),
        SpaceChannel(roomId: '!a', name: '', listedAt: 1),
        SpaceChannel(roomId: '!first', name: '', listedAt: 0),
      ]);

      expect(ordered.map((c) => c.roomId), ['!first', '!a', '!z', '!unknown']);
    });
  });

  group('joinableSubspaces', () {
    test('always_keepsOpenSubSpacesNotJoinedYet', () {
      final offered = joinableSubspaces(const [
        SpaceChannel(
          roomId: '!open',
          name: '',
          isSpace: true,
          isJoinable: true,
        ),
        SpaceChannel(roomId: '!private', name: '', isSpace: true),
        SpaceChannel(
          roomId: '!joined',
          name: '',
          isSpace: true,
          isJoinable: true,
          isJoined: true,
        ),
        SpaceChannel(roomId: '!channel', name: '', isJoinable: true),
      ]);

      expect(offered.map((c) => c.roomId), ['!open']);
    });
  });
}

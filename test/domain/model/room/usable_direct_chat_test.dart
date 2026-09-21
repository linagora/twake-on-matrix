import 'package:twake_chat/domain/model/room/room_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';

import 'room_extension_test.mocks.dart';

class _FakeSummary extends Fake implements RoomSummary {
  _FakeSummary(this.joined);
  final int? joined;
  @override
  int? get mJoinedMemberCount => joined;
}

class _FakeMember extends Fake implements User {
  _FakeMember(this._id);
  final String _id;
  @override
  String get id => _id;
}

MockRoom _room({
  required String? peer,
  required int? joined,
  List<User> members = const [],
}) {
  final room = MockRoom();
  when(room.directChatMatrixID).thenReturn(peer);
  when(room.summary).thenReturn(_FakeSummary(joined));
  when(
    room.getParticipants([Membership.join, Membership.invite]),
  ).thenReturn(members);
  return room;
}

void main() {
  const alice = '@alice:example.com';
  const bob = '@bob:example.com';
  const me = '@me:example.com';

  group('Room.isUsableDirectChatWith', () {
    test('accepts DM with matching peer and intended member', () {
      final room = _room(
        peer: alice,
        joined: 2,
        members: [_FakeMember(me), _FakeMember(alice)],
      );

      expect(room.isUsableDirectChatWith(alice), isTrue);
    });

    test('rejects group mis-mapped in m.direct (joined > 2)', () {
      final room = _room(peer: alice, joined: 5);

      expect(room.isUsableDirectChatWith(alice), isFalse);
    });

    test('rejects wrong peer', () {
      final room = _room(peer: bob, joined: 2);

      expect(room.isUsableDirectChatWith(alice), isFalse);
    });

    test('accepts when peer not synced yet and members empty', () {
      final room = _room(peer: null, joined: 1);

      expect(room.isUsableDirectChatWith(alice), isTrue);
    });

    test('accepts when joined count is null (unknown)', () {
      final room = _room(peer: alice, joined: null);

      expect(room.isUsableDirectChatWith(alice), isTrue);
    });

    test('rejects stale m.direct when members are another contact', () {
      final room = _room(
        peer: alice,
        joined: 2,
        members: [_FakeMember(me), _FakeMember(bob)],
      );

      expect(room.isUsableDirectChatWith(alice), isFalse);
    });

    test('accepts when intended user is among known members', () {
      final room = _room(
        peer: alice,
        joined: 2,
        members: [_FakeMember(me), _FakeMember(alice)],
      );

      expect(room.isUsableDirectChatWith(alice), isTrue);
    });

    test('accepts post-create when only self is known so far', () {
      final room = _room(peer: alice, joined: 1, members: [_FakeMember(me)]);

      expect(room.isUsableDirectChatWith(alice), isTrue);
    });
  });
}

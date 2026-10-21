import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/presentation/extensions/client_extension.dart';

class _FakeRoom extends Fake implements Room {
  _FakeRoom(this.id, this.membership);

  @override
  final String id;

  @override
  final Membership membership;
}

class _FakeClient extends Fake implements Client {
  _FakeClient(this.rooms);

  @override
  final List<Room> rooms;
}

void main() {
  group('ClientExtension.joinedOrInvitedRooms', () {
    test('keeps joined and invited rooms only', () {
      final client = _FakeClient([
        _FakeRoom('!joined:example.org', Membership.join),
        _FakeRoom('!invited:example.org', Membership.invite),
        _FakeRoom('!left:example.org', Membership.leave),
        _FakeRoom('!banned:example.org', Membership.ban),
        _FakeRoom('!knocked:example.org', Membership.knock),
      ]);

      expect(client.joinedOrInvitedRooms.map((room) => room.id), [
        '!joined:example.org',
        '!invited:example.org',
      ]);
    });

    test('returns an empty list when there are no rooms', () {
      expect(_FakeClient([]).joinedOrInvitedRooms, isEmpty);
    });
  });
}

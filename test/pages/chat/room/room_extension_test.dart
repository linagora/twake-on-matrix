import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';

import '../../../fake_client.dart';

void main() {
  group('Room extension and canUpdateRoleInRoom test', () {
    late Client client;

    late Room room;

    test('Login', () async {
      client = await getClient();
      const id = '!localpart:server.abc';
      const membership = Membership.join;
      const notificationCount = 2;
      const highlightCount = 1;
      room = Room(
        client: client,
        id: id,
        membership: membership,
        highlightCount: highlightCount,
        notificationCount: notificationCount,
        prev_batch: '',
        summary: RoomSummary.fromJson({'m.joined_member_count': 3}),
        roomAccountData: {
          'com.test.foo': BasicEvent(
            type: 'com.test.foo',
            content: {'foo': 'bar'},
          ),
          'm.fully_read': BasicEvent(
            type: 'm.fully_read',
            content: {'event_id': '\$event_id:example.com'},
          ),
          'm.room.member': BasicEvent(
            type: 'm.room.member',
            content: {
              'membership': membership.toString(),
              'displayname': 'Test User',
              'avatar_url': 'mxc://example.com/avatar',
            },
          ),
        },
      );

      room.setState(
        Event(
          senderId: '@alice:test.abc',
          type: 'm.room.member',
          room: room,
          eventId: '12345',
          originServerTs: DateTime.now(),
          content: {'displayname': 'alice'},
          stateKey: '@alice:test.abc',
        ),
      );

      room.setState(
        Event(
          senderId: '@bob:test.abc',
          type: 'm.room.member',
          room: room,
          eventId: '54312',
          originServerTs: DateTime.now(),
          content: {'displayname': 'alice'},
          stateKey: '@bob:test.abc',
        ),
      );

      room.setState(
        Event(
          senderId: '@ccc:test.abc',
          type: 'm.room.member',
          room: room,
          eventId: '43212',
          originServerTs: DateTime.now(),
          content: {'displayname': 'alice'},
          stateKey: '@ccc:test.abc',
        ),
      );

      expect(room.id, id);
      expect(room.membership, membership);
      expect(room.notificationCount, notificationCount);
      expect(room.highlightCount, highlightCount);
      expect(room.summary.mJoinedMemberCount, 3);
    });

    test('PowerLevels', () async {
      room.setState(
        Event(
          senderId: '@alice:test.abc',
          type: 'm.room.power_levels',
          room: room,
          eventId: '123',
          content: {
            'ban': 50,
            'events': {'m.room.name': 100, 'm.room.power_levels': 100},
            'events_default': 0,
            'invite': 50,
            'kick': 50,
            'notifications': {'room': 20},
            'redact': 50,
            'state_default': 50,
            'users': {
              '@admin:fakeServer': 100,
              '@alice:test.abc': 0,
              '@bob:test.abc': 0,
              '@ccc:test.abc': 0,
            },
            'users_default': 0,
          },
          originServerTs: DateTime.now(),
          stateKey: '',
        ),
      );

      expect(room.getPowerLevelByUserId(client.userID!), room.ownPowerLevel);
    });

    test('Given @alice:matrix.org is admin'
        'THEN canUpdateRoleInRoom return true', () {
      room.setState(
        Event(
          senderId: '@alice:test.abc',
          type: 'm.room.power_levels',
          room: room,
          eventId: '123',
          content: {
            'ban': 50,
            'events': {'m.room.name': 100, 'm.room.power_levels': 100},
            'events_default': 0,
            'invite': 50,
            'kick': 50,
            'notifications': {'room': 20},
            'redact': 50,
            'state_default': 50,
            'users': {'@admin:fakeServer': 100, '@alice:test.abc': 80},
            'users_default': 0,
          },
          originServerTs: DateTime.now(),
          stateKey: '',
        ),
      );

      final member = room.getParticipants().firstWhere((member) {
        return member.id == '@alice:test.abc';
      });

      expect(room.canUpdateRoleInRoom(member), true);
    });

    test('Given @alice:matrix.org is Moderator'
        'THEN canUpdateRoleInRoom return false', () {
      room.setState(
        Event(
          senderId: '@alice:test.abc',
          type: 'm.room.power_levels',
          room: room,
          eventId: '123',
          content: {
            'users': {
              'ban': 50,
              'events': {'m.room.name': 100, 'm.room.power_levels': 100},
              'events_default': 0,
              'invite': 50,
              'kick': 50,
              'notifications': {'room': 20},
              'redact': 50,
              'state_default': 50,
              'users': {'@admin:fakeServer': 100, '@alice:test.abc': 50},
            },
          },
          originServerTs: DateTime.now(),
          stateKey: '',
        ),
      );

      final member = room.getParticipants().firstWhere((member) {
        return member.id == '@alice:test.abc';
      });

      expect(room.canUpdateRoleInRoom(member), false);
    });

    test('Given @alice:matrix.org is Member'
        'THEN canUpdateRoleInRoom return false', () {
      room.setState(
        Event(
          senderId: '@alice:test.abc',
          type: 'm.room.power_levels',
          room: room,
          eventId: '123',
          content: {
            'users': {
              'ban': 50,
              'events': {'m.room.name': 100, 'm.room.power_levels': 100},
              'events_default': 0,
              'invite': 50,
              'kick': 50,
              'notifications': {'room': 20},
              'redact': 50,
              'state_default': 50,
              'users': {'@admin:fakeServer': 100, '@alice:test.abc': 10},
            },
          },
          originServerTs: DateTime.now(),
          stateKey: '',
        ),
      );

      final member = room.getParticipants().firstWhere((member) {
        return member.id == '@alice:test.abc';
      });

      expect(room.canUpdateRoleInRoom(member), false);
    });

    test('Given @alice:matrix.org is Guest'
        'THEN canUpdateRoleInRoom return false', () {
      room.setState(
        Event(
          senderId: '@alice:test.abc',
          type: 'm.room.power_levels',
          room: room,
          eventId: '123',
          content: {
            'users': {
              'ban': 50,
              'events': {'m.room.name': 100, 'm.room.power_levels': 100},
              'events_default': 0,
              'invite': 50,
              'kick': 50,
              'notifications': {'room': 20},
              'redact': 50,
              'state_default': 50,
              'users': {'@admin:fakeServer': 100, '@alice:test.abc': 0},
            },
          },
          originServerTs: DateTime.now(),
          stateKey: '',
        ),
      );

      final member = room.getParticipants().firstWhere((member) {
        return member.id == '@alice:test.abc';
      });

      expect(room.canUpdateRoleInRoom(member), false);
    });
  });
}

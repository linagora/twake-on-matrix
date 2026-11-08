import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
// ignore: implementation_imports
import 'package:matrix/src/utils/space_child.dart';
import 'package:twake_chat/data/datasource_impl/spaces/room_list_entry_mapper.dart';
import 'package:twake_chat/domain/spaces/room_list_entry.dart';

import '../../../fake_client.dart' show MockDatabase;
import 'room_list_entry_mapper_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Room>()])
StrippedStateEvent _relation(String type, String key) => StrippedStateEvent(
  type: type,
  senderId: '@a:b',
  stateKey: key,
  content: {
    'via': ['b'],
  },
);

/// Marks the last parent [room] names as its `canonical: true` one.
MockRoom _withLastParentCanonical(MockRoom room) {
  final parents = room.spaceParents;
  when(room.spaceParents).thenReturn([
    ...parents.take(parents.length - 1),
    SpaceParent.fromState(
      StrippedStateEvent(
        type: EventTypes.SpaceParent,
        senderId: '@a:b',
        stateKey: parents.last.roomId,
        content: {
          'via': ['b'],
          'canonical': true,
        },
      ),
    ),
  ]);
  return room;
}

const String _parentSender = '@sender:b.org';

MockRoom _room(
  String id, {
  bool isSpace = false,
  List<String> children = const [],
  List<String> parents = const [],
}) {
  final room = MockRoom();
  when(room.id).thenReturn(id);
  when(room.isSpace).thenReturn(isSpace);
  when(room.membership).thenReturn(Membership.join);
  when(room.tags).thenReturn({});
  when(room.spaceChildren).thenReturn([
    for (final child in children)
      SpaceChild.fromState(_relation(EventTypes.SpaceChild, child)),
  ]);
  when(room.spaceParents).thenReturn([
    for (final parent in parents)
      SpaceParent.fromState(_relation(EventTypes.SpaceParent, parent)),
  ]);
  for (final parent in parents) {
    when(room.getState(EventTypes.SpaceParent, parent)).thenReturn(
      Event(
        type: EventTypes.SpaceParent,
        stateKey: parent,
        senderId: _parentSender,
        eventId: '\$parent',
        originServerTs: DateTime(2026),
        content: const {},
        room: room,
      ),
    );
  }
  when(
    room.powerForChangingStateEvent(EventTypes.SpaceChild),
  ).thenReturn(PowerLevel(50));
  when(room.getPowerLevelByUserId(_parentSender)).thenReturn(PowerLevel(50));
  return room;
}

List<RoomListEntry> entriesOf(
  List<Room> rooms, {
  Map<String, List<String>> directChats = const {},
}) => roomListEntriesOf(rooms, directChats: directChats);

RoomKind _kindWithState(
  String eventType,
  Map<String, Object?> content, {
  bool isSpace = false,
}) {
  final room = _room('!c', isSpace: isSpace);
  when(room.getState(eventType)).thenReturn(
    StrippedStateEvent(
      type: eventType,
      senderId: '@a:b',
      stateKey: '',
      content: content,
    ),
  );
  return entriesOf([room]).single.kind;
}

RoomKind _directKind(String partner) {
  final room = _room('!c');
  when(room.name).thenReturn('Named');
  final directChats = {
    partner: ['!c'],
  };
  return entriesOf([room], directChats: directChats).single.kind;
}

List<String> _parentsWhenSenderHas(PowerLevel level, {bool isListed = false}) {
  final space = _room(
    '!space',
    isSpace: true,
    children: isListed ? const ['!c'] : const [],
  );
  when(space.getPowerLevelByUserId(_parentSender)).thenReturn(level);
  return entriesOf([
    space,
    _room('!c', parents: const ['!space']),
  ]).last.parentSpaceIds;
}

void main() {
  _roomListEntriesOfTests();
  _roomListEntriesOfSpacesTests();
  _unnamedDirectChatTests();
  _kindTests();
  _kindDirectTests();
  _kindPowerLevelTests();
}

late Client _client;

Room _direct({
  required Map<String, Object?> summary,
  String partner = '@alice:b.org',
  Membership partnerMembership = Membership.join,
}) {
  final room = Room(
    id: '!dm',
    client: _client,
    summary: RoomSummary.fromJson(summary),
  );
  room.setState(
    Event(
      type: EventTypes.RoomMember,
      content: {'membership': partnerMembership.name, 'displayname': 'Alice'},
      stateKey: partner,
      eventId: r'$m',
      senderId: partner,
      originServerTs: DateTime(2020),
      room: room,
    ),
  );
  _client.accountData['m.direct'] = BasicEvent(
    type: 'm.direct',
    content: {
      partner: ['!dm'],
    },
  );
  return room;
}

void _roomListEntriesOfTests() {
  group('roomListEntriesOf', () {
    test('whenSenderMayNotListInTheSpace_ignoresTheParentItNames', () {
      expect(_parentsWhenSenderHas(PowerLevel(49)), isEmpty);
    });

    test('whenTheSpaceListsTheRoom_keepsItWhoeverNamedTheParent', () {
      expect(_parentsWhenSenderHas(PowerLevel(0), isListed: true), ['!space']);
    });

    test('whenSpacesListAndAreNamed_putsThoseListingFirst', () {
      final entries = entriesOf([
        _room('!named', isSpace: true),
        _room('!listing', isSpace: true, children: ['!c']),
        _room('!c', parents: ['!named', '!listing']),
      ]);

      expect(entries.last.parentSpaceIds, ['!listing', '!named']);
    });

    test('whenAJoinedSpaceIsCanonical_putsItFirst', () {
      final entries = entriesOf([
        _room('!a', isSpace: true, children: ['!c']),
        _room('!z', isSpace: true, children: ['!c']),
        _withLastParentCanonical(_room('!c', parents: ['!a', '!z'])),
      ]);

      expect(entries.last.parentSpaceIds, ['!z', '!a']);
    });

    test('whenTheCanonicalSpaceIsNotJoined_ignoresIt', () {
      final entries = entriesOf([
        _room('!a', isSpace: true, children: ['!c']),
        _withLastParentCanonical(_room('!c', parents: ['!a', '!gone'])),
      ]);

      expect(entries.last.parentSpaceIds, ['!a']);
    });

    test('whenInSeveralSpaces_theFirstDoesNotFollowTheRoomOrder', () {
      Room channel() => _room('!c');
      Room space(String id) => _room(id, isSpace: true, children: ['!c']);

      final one = entriesOf([space('!a'), space('!b'), channel()]);
      final other = entriesOf([space('!b'), space('!a'), channel()]);

      expect(one.last.parentSpaceIds, ['!a', '!b']);
      expect(other.last.parentSpaceIds, ['!a', '!b']);
    });
  });
}

void _roomListEntriesOfSpacesTests() {
  group('roomListEntriesOf', () {
    test('whenSpaceIsNotJoined_holdsNothing', () {
      final invited = _room('!invited', isSpace: true, children: ['!c']);
      when(invited.membership).thenReturn(Membership.invite);
      final entries = entriesOf([
        invited,
        _room('!c', parents: ['!invited', '!unknown']),
      ]);

      expect(entries.last.parentSpaceIds, isEmpty);
      expect(entries.first.isJoined, isFalse);
      expect(entries.first.isMarkedUnread, isTrue);
    });

    test('whenSpace_tellsWhatItListsAndWhetherUserMayAdd', () {
      final space = _room('!s', isSpace: true, children: ['!a', '!b']);
      when(space.canChangeStateEvent(EventTypes.SpaceChild)).thenReturn(true);

      final entry = entriesOf([space]).single;

      expect(entry.childIds, ['!a', '!b']);
      expect(entry.canAddChildren, isTrue);
    });

    test('whenTagged_readsTheFolderFromTheTag', () {
      final room = _room('!c');
      when(room.tags).thenReturn({'u.Work': Tag(), 'm.favourite': Tag()});

      expect(entriesOf([room]).single.folders, ['Work']);
    });

    test('whenTagIsOnlyThePrefix_hasNoFolder', () {
      final room = _room('!c');
      when(room.tags).thenReturn({'u.': Tag(), 'u.Work': Tag()});

      expect(entriesOf([room]).single.folders, ['Work']);
    });
  });
}

void _unnamedDirectChatTests() {
  group('roomListEntriesOf', () {
    group('nameOfAnUnnamedDirectChat', () {
      setUp(() => _client = Client('names', database: MockDatabase()));

      test('whenHeroesAreKnown_isTheNameTheSdkGives', () {
        final room = _direct(
          summary: {
            'm.heroes': ['@alice:b.org'],
          },
        );

        final entry = entriesOf([
          room,
        ], directChats: _client.directChats).single;

        expect(entry.name, 'Alice');
        expect(entry.name, room.getLocalizedDisplayname());
      });

      test('whenNoHeroes_isThePartner', () {
        final room = _direct(summary: {});

        final entry = entriesOf([
          room,
        ], directChats: _client.directChats).single;

        expect(entry.name, 'Alice');
        expect(entry.name, room.getLocalizedDisplayname());
      });

      test('whenPartnerLeft_isTheNameTheSdkGives', () {
        final room = _direct(
          summary: {
            'm.heroes': ['@alice:b.org'],
            'm.joined_member_count': 1,
            'm.invited_member_count': 0,
          },
          partnerMembership: Membership.leave,
        );

        final entry = entriesOf([
          room,
        ], directChats: _client.directChats).single;

        expect(entry.name, isNot('Alice'));
        expect(entry.name, room.getLocalizedDisplayname());
      });
    });
  });
}

void _kindTests() {
  group('roomListEntriesOf', () {
    group('kind', () {
      test('always_carriesTheAvatar', () {
        final room = _room('!c');
        final avatar = Uri.parse('mxc://b.org/a');
        when(room.avatar).thenReturn(avatar);

        expect(entriesOf([room]).single.avatar, avatar);
      });

      test('whenTwoUsersListTheRoom_followsTheFirstLikeTheSdk', () {
        final room = _room('!c');
        when(room.name).thenReturn('Named');

        RoomKind kindWith(Map<String, List<String>> directChats) =>
            entriesOf([room], directChats: directChats).single.kind;

        expect(
          kindWith({
            '@alice:b.org': ['!c'],
            '@bot_x:b.org': ['!c'],
          }),
          RoomKind.direct,
        );
        expect(
          kindWith({
            'not an id': ['!c'],
            '@alice:b.org': ['!c'],
          }),
          RoomKind.group,
        );
      });

      test('whenDirectWithABot_isBot', () {
        final kind = _directKind('@bot_x:b.org');

        expect(kind, RoomKind.bot);
      });

      test('whenDirectWithAPerson_isDirect', () {
        final kind = _directKind('@alice:b.org');

        expect(kind, RoomKind.direct);
      });

      test('whenPartnerIsNotAnId_isNotDirect', () {
        final kind = _directKind('alice');

        expect(kind, RoomKind.group);
      });
    });
  });
}

void _kindDirectTests() {
  group('roomListEntriesOf', () {
    group('kind', () {
      test('whenDirect_doesNotAskTheRoomForItsPartner', () {
        final room = _room('!c');
        when(room.name).thenReturn('Alice');

        entriesOf(
          [room],
          directChats: {
            '@alice:b.org': ['!c'],
          },
        );

        // Each of these rebuilds all the direct chats of the account.
        verifyNever(room.directChatMatrixID);
        verifyNever(room.isDirectChat);
      });

      test('whenInvitedToADirectChat_asksTheRoomForTheSender', () {
        final room = _room('!c');
        when(room.membership).thenReturn(Membership.invite);
        when(room.directChatMatrixID).thenReturn('@bot_x:b.org');

        expect(entriesOf([room]).single.kind, RoomKind.bot);
      });

      test('whenFeed_isBroadcast', () {
        final kind = _kindWithState(EventTypes.RoomCreate, {
          'type': 'app.twake.chat.feed',
        });

        expect(kind, RoomKind.broadcast);
      });

      test('whenMembersMayNotPost_isBroadcast', () {
        final kind = _kindWithState(EventTypes.RoomPowerLevels, {
          'events_default': 50,
        });

        expect(kind, RoomKind.broadcast);
      });
    });
  });
}

void _kindPowerLevelTests() {
  group('roomListEntriesOf', () {
    group('kind', () {
      test('whenMembersMayNotPostMessages_isBroadcast', () {
        final kind = _kindWithState(EventTypes.RoomPowerLevels, {
          'events': {EventTypes.Message: 50},
        });

        expect(kind, RoomKind.broadcast);
      });

      test('whenMessagesAreOpenButDefaultIsNot_isGroup', () {
        final kind = _kindWithState(EventTypes.RoomPowerLevels, {
          'events': {EventTypes.Message: 0},
          'events_default': 50,
        });

        expect(kind, RoomKind.group);
      });

      test('whenMembersMayPost_isGroup', () {
        final kind = _kindWithState(EventTypes.RoomPowerLevels, {
          'events_default': 50,
          'users_default': 50,
        });

        expect(kind, RoomKind.group);
      });

      test('whenSpaceLooksLikeABroadcast_staysASpace', () {
        final kind = _kindWithState(EventTypes.RoomPowerLevels, {
          'events_default': 100,
        }, isSpace: true);

        expect(kind, RoomKind.space);
      });
    });
  });
}

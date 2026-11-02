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

MockRoom _room(
  String id, {
  bool isSpace = false,
  Membership membership = Membership.join,
  List<String> children = const [],
  List<String> parents = const [],
}) {
  final room = MockRoom();
  when(room.id).thenReturn(id);
  when(room.isSpace).thenReturn(isSpace);
  when(room.membership).thenReturn(membership);
  when(room.tags).thenReturn({});
  when(room.spaceChildren).thenReturn([
    for (final child in children)
      SpaceChild.fromState(_relation(EventTypes.SpaceChild, child)),
  ]);
  when(room.spaceParents).thenReturn([
    for (final parent in parents)
      SpaceParent.fromState(_relation(EventTypes.SpaceParent, parent)),
  ]);
  return room;
}

List<RoomListEntry> entriesOf(
  List<Room> rooms, {
  Map<String, List<String>> directChats = const {},
}) => roomListEntriesOf(rooms, directChats: directChats);

StrippedStateEvent _state(String type, Map<String, Object?> content) =>
    StrippedStateEvent(
      type: type,
      senderId: '@a:b',
      stateKey: '',
      content: content,
    );

void main() {
  group('roomListEntriesOf', () {
    test('whenSpacesListAndAreNamed_putsThoseListingFirst', () {
      final entries = entriesOf([
        _room('!named', isSpace: true),
        _room('!listing', isSpace: true, children: ['!c']),
        _room('!c', parents: ['!named', '!listing']),
      ]);

      expect(entries.last.parentSpaceIds, ['!listing', '!named']);
    });

    test('whenInSeveralSpaces_theFirstDoesNotFollowTheRoomOrder', () {
      Room channel() => _room('!c');
      Room space(String id) => _room(id, isSpace: true, children: ['!c']);

      final one = entriesOf([space('!a'), space('!b'), channel()]);
      final other = entriesOf([space('!b'), space('!a'), channel()]);

      expect(one.last.parentSpaceIds, ['!a', '!b']);
      expect(other.last.parentSpaceIds, ['!a', '!b']);
    });

    test('whenSpaceIsNotJoined_holdsNothing', () {
      final entries = entriesOf([
        _room(
          '!invited',
          isSpace: true,
          membership: Membership.invite,
          children: ['!c'],
        ),
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

    group('nameOfAnUnnamedDirectChat', () {
      late Client client;

      Room direct({
        required Map<String, Object?> summary,
        String partner = '@alice:b.org',
        Membership partnerMembership = Membership.join,
      }) {
        final room = Room(
          id: '!dm',
          client: client,
          summary: RoomSummary.fromJson(summary),
        );
        room.setState(
          Event(
            type: EventTypes.RoomMember,
            content: {
              'membership': partnerMembership.name,
              'displayname': 'Alice',
            },
            stateKey: partner,
            eventId: r'$m',
            senderId: partner,
            originServerTs: DateTime(2020),
            room: room,
          ),
        );
        client.accountData['m.direct'] = BasicEvent(
          type: 'm.direct',
          content: {
            partner: ['!dm'],
          },
        );
        return room;
      }

      setUp(() => client = Client('names', database: MockDatabase()));

      test('whenHeroesAreKnown_isTheNameTheSdkGives', () {
        final room = direct(
          summary: {
            'm.heroes': ['@alice:b.org'],
          },
        );

        final entry = entriesOf([room], directChats: client.directChats).single;

        expect(entry.name, 'Alice');
        expect(entry.name, room.getLocalizedDisplayname());
      });

      test('whenNoHeroes_isThePartner', () {
        final room = direct(summary: {});

        final entry = entriesOf([room], directChats: client.directChats).single;

        expect(entry.name, 'Alice');
        expect(entry.name, room.getLocalizedDisplayname());
      });

      test('whenPartnerLeft_isTheNameTheSdkGives', () {
        final room = direct(
          summary: {
            'm.heroes': ['@alice:b.org'],
            'm.joined_member_count': 1,
            'm.invited_member_count': 0,
          },
          partnerMembership: Membership.leave,
        );

        final entry = entriesOf([room], directChats: client.directChats).single;

        expect(entry.name, isNot('Alice'));
        expect(entry.name, room.getLocalizedDisplayname());
      });
    });

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
        final room = _room('!c');
        when(room.name).thenReturn('Bot');

        final entries = entriesOf(
          [room],
          directChats: {
            '@bot_x:b.org': ['!c'],
          },
        );

        expect(entries.single.kind, RoomKind.bot);
      });

      test('whenDirectWithAPerson_isDirect', () {
        final room = _room('!c');
        when(room.name).thenReturn('Alice');

        final entries = entriesOf(
          [room],
          directChats: {
            '@alice:b.org': ['!c'],
          },
        );

        expect(entries.single.kind, RoomKind.direct);
      });

      test('whenPartnerIsNotAnId_isNotDirect', () {
        final entries = entriesOf(
          [_room('!c')],
          directChats: {
            'alice': ['!c'],
          },
        );

        expect(entries.single.kind, RoomKind.group);
      });

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
        final room = _room('!c', membership: Membership.invite);
        when(room.directChatMatrixID).thenReturn('@bot_x:b.org');

        expect(entriesOf([room]).single.kind, RoomKind.bot);
      });

      test('whenFeed_isBroadcast', () {
        final room = _room('!c');
        when(room.getState(EventTypes.RoomCreate)).thenReturn(
          _state(EventTypes.RoomCreate, {'type': 'app.twake.chat.feed'}),
        );

        expect(entriesOf([room]).single.kind, RoomKind.broadcast);
      });

      test('whenMembersMayNotPost_isBroadcast', () {
        final room = _room('!c');
        when(room.getState(EventTypes.RoomPowerLevels)).thenReturn(
          _state(EventTypes.RoomPowerLevels, {'events_default': 50}),
        );

        expect(entriesOf([room]).single.kind, RoomKind.broadcast);
      });

      test('whenMembersMayNotPostMessages_isBroadcast', () {
        final room = _room('!c');
        when(room.getState(EventTypes.RoomPowerLevels)).thenReturn(
          _state(EventTypes.RoomPowerLevels, {
            'events': {EventTypes.Message: 50},
          }),
        );

        expect(entriesOf([room]).single.kind, RoomKind.broadcast);
      });

      test('whenMessagesAreOpenButDefaultIsNot_isGroup', () {
        final room = _room('!c');
        when(room.getState(EventTypes.RoomPowerLevels)).thenReturn(
          _state(EventTypes.RoomPowerLevels, {
            'events': {EventTypes.Message: 0},
            'events_default': 50,
          }),
        );

        expect(entriesOf([room]).single.kind, RoomKind.group);
      });

      test('whenMembersMayPost_isGroup', () {
        final room = _room('!c');
        when(room.getState(EventTypes.RoomPowerLevels)).thenReturn(
          _state(EventTypes.RoomPowerLevels, {
            'events_default': 50,
            'users_default': 50,
          }),
        );

        expect(entriesOf([room]).single.kind, RoomKind.group);
      });

      test('whenSpaceLooksLikeABroadcast_staysASpace', () {
        final room = _room('!c', isSpace: true);
        when(room.getState(EventTypes.RoomPowerLevels)).thenReturn(
          _state(EventTypes.RoomPowerLevels, {'events_default': 100}),
        );

        expect(entriesOf([room]).single.kind, RoomKind.space);
      });
    });
  });
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
// ignore: implementation_imports
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/datasource_impl/spaces/space_datasource_impl.dart';
import 'package:twake_chat/domain/exception/spaces/space_exception.dart';
import 'package:twake_chat/domain/spaces/new_space.dart';

import 'space_datasource_impl_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Client>(), MockSpec<Room>()])
void main() {
  const newRoomId = '!new:own.org';
  late MockClient client;
  late SpaceDatasourceImpl datasource;

  void whenCreateRoom(Future<String> Function() answer) => when(
    client.createRoom(
      name: anyNamed('name'),
      topic: anyNamed('topic'),
      preset: anyNamed('preset'),
      visibility: anyNamed('visibility'),
      creationContent: anyNamed('creationContent'),
      powerLevelContentOverride: anyNamed('powerLevelContentOverride'),
      initialState: anyNamed('initialState'),
    ),
  ).thenAnswer((_) => answer());

  setUp(() {
    client = MockClient();
    datasource = SpaceDatasourceImpl(client);
    when(client.userID).thenReturn('@me:own.org');
    final newRoom = MockRoom();
    when(client.getRoomById(newRoomId)).thenReturn(newRoom);
    whenCreateRoom(() async => newRoomId);
  });

  ({
    CreateRoomPreset preset,
    Visibility? visibility,
    Map<String, Object?>? creationContent,
    Map<String, StateEvent> state,
  })
  requested() {
    final captured = verify(
      client.createRoom(
        name: anyNamed('name'),
        topic: anyNamed('topic'),
        preset: captureAnyNamed('preset'),
        visibility: captureAnyNamed('visibility'),
        creationContent: captureAnyNamed('creationContent'),
        powerLevelContentOverride: anyNamed('powerLevelContentOverride'),
        initialState: captureAnyNamed('initialState'),
      ),
    ).captured;
    return (
      preset: captured[0] as CreateRoomPreset,
      visibility: captured[1] as Visibility?,
      creationContent: captured[2] as Map<String, Object?>?,
      state: {
        for (final event in captured[3] as List<StateEvent>) event.type: event,
      },
    );
  }

  group('createSpace', () {
    test('whenPrivate_isInTheClearWithNoStateOfItsOwn', () async {
      await datasource.createSpace(const NewSpace(name: 'Team'));

      final request = requested();
      expect(request.preset, CreateRoomPreset.privateChat);
      expect(request.visibility, isNull);
      expect(request.creationContent, {'type': 'm.space'});
      expect(request.state, isEmpty);
    });

    test('whenPublic_listsIt', () async {
      await datasource.createSpace(
        const NewSpace(name: 'Team', isPublic: true),
      );

      final request = requested();
      expect(request.preset, CreateRoomPreset.publicChat);
      expect(request.visibility, Visibility.public);
    });

    test('whenLimitedToTheServer_doesNotFederate', () async {
      await datasource.createSpace(
        const NewSpace(name: 'Team', isPublic: true, isServerLimited: true),
      );

      expect(requested().creationContent, {
        'type': 'm.space',
        'm.federate': false,
      });
    });

    test('whenItHasAPicture_setsIt', () async {
      await datasource.createSpace(
        const NewSpace(name: 'Team', urlAvatar: 'mxc://own.org/a'),
      );

      expect(requested().state[EventTypes.RoomAvatar]!.content, {
        'url': 'mxc://own.org/a',
      });
    });

    group('whenInASpace', () {
      const space = '!space:other.org';
      const subspace = NewSpace(name: 'Sub', parentSpaceId: space);

      test('namesItsSpaceAndOpensToItsMembers', () async {
        await datasource.createSpace(subspace);

        final state = requested().state;
        final parent = state[EventTypes.SpaceParent]!;
        expect(parent.stateKey, space);
        expect(parent.content, {
          'via': ['other.org', 'own.org'],
          'canonical': true,
        });
        expect(state[EventTypes.RoomJoinRules]!.content, {
          'join_rule': 'restricted',
          'allow': [
            {'type': 'm.room_membership', 'room_id': space},
          ],
        });
      });

      test('whenRoomIdHasNoServer_namesOnlyTheUsers', () async {
        await datasource.createSpace(subspace.copyWith(parentSpaceId: '!Abc'));

        expect(requested().state[EventTypes.SpaceParent]!.content['via'], [
          'own.org',
        ]);
      });

      test('listsItInTheSpace', () async {
        await datasource.createSpace(subspace);

        verify(
          client.setRoomStateWithKey(space, EventTypes.SpaceChild, newRoomId, {
            'via': ['own.org'],
          }),
        ).called(1);
      });

      test('whenPublic_isNotRestricted', () async {
        await datasource.createSpace(subspace.copyWith(isPublic: true));

        final state = requested().state;
        expect(state.containsKey(EventTypes.RoomJoinRules), isFalse);
        expect(state.containsKey(EventTypes.SpaceParent), isTrue);
      });

      test('whenSpaceRefuses_removesTheRoom', () async {
        when(client.setRoomStateWithKey(any, any, any, any)).thenThrow(
          MatrixException.fromJson({'errcode': 'M_FORBIDDEN', 'error': 'no'}),
        );

        await expectLater(
          datasource.createSpace(subspace),
          throwsA(isA<SpaceForbiddenException>()),
        );
        verify(client.leaveRoom(newRoomId)).called(1);
        verify(client.forgetRoom(newRoomId)).called(1);
      });

      test('whenRemovalFails_stillTellsWhyItFailed', () async {
        when(client.setRoomStateWithKey(any, any, any, any)).thenThrow(
          MatrixException.fromJson({'errcode': 'M_FORBIDDEN', 'error': 'no'}),
        );
        when(client.leaveRoom(any)).thenThrow(Exception('down'));

        await expectLater(
          datasource.createSpace(subspace),
          throwsA(isA<SpaceForbiddenException>()),
        );
      });

      test('whenUserMayNotAdd_createsNothing', () async {
        final parent = MockRoom();
        when(client.getRoomById(space)).thenReturn(parent);
        when(
          parent.canChangeStateEvent(EventTypes.SpaceChild),
        ).thenReturn(false);

        await expectLater(
          datasource.createSpace(subspace),
          throwsA(isA<SpaceForbiddenException>()),
        );
        verifyNever(
          client.createRoom(
            name: anyNamed('name'),
            preset: anyNamed('preset'),
            initialState: anyNamed('initialState'),
          ),
        );
      });
    });

    test('whenTheRoomIsNotSyncedYet_waitsForIt', () async {
      when(client.getRoomById(newRoomId)).thenReturn(null);

      await datasource.createSpace(const NewSpace(name: 'Team'));

      verify(client.waitForRoomInSync(newRoomId, join: true)).called(1);
    });

    test('whenTheRoomIsSynced_doesNotWait', () async {
      await datasource.createSpace(const NewSpace(name: 'Team'));

      verifyNever(client.waitForRoomInSync(any, join: anyNamed('join')));
    });

    test('whenListingNeverGotAnAnswer_keepsTheRoom', () async {
      when(
        client.setRoomStateWithKey(any, any, any, any),
      ).thenThrow(TimeoutException('no answer'));

      await expectLater(
        datasource.createSpace(
          const NewSpace(name: 'Sub', parentSpaceId: '!space:other.org'),
        ),
        throwsA(isA<SpaceCreationFailedException>()),
      );
      verifyNever(client.leaveRoom(newRoomId));
      verifyNever(client.forgetRoom(newRoomId));
    });

    test('whenTheServerAnswersAnotherError_removesTheRoom', () async {
      when(client.setRoomStateWithKey(any, any, any, any)).thenThrow(
        MatrixException.fromJson({'errcode': 'M_UNKNOWN', 'error': 'down'}),
      );

      await expectLater(
        datasource.createSpace(
          const NewSpace(name: 'Sub', parentSpaceId: '!space:other.org'),
        ),
        throwsA(isA<SpaceCreationFailedException>()),
      );
      verify(client.leaveRoom(newRoomId)).called(1);
      verify(client.forgetRoom(newRoomId)).called(1);
    });

    test('whenAnythingElseFails_throwsTyped', () async {
      whenCreateRoom(() => throw Exception('down'));

      await expectLater(
        datasource.createSpace(const NewSpace(name: 'Team')),
        throwsA(isA<SpaceCreationFailedException>()),
      );
    });
  });

  group('getSpace', () {
    test('whenNoJoinedSpace_returnsNull', () {
      final room = MockRoom();
      when(room.isSpace).thenReturn(false);
      when(room.membership).thenReturn(Membership.join);
      when(client.getRoomById('!room')).thenReturn(room);
      final invited = MockRoom();
      when(invited.isSpace).thenReturn(true);
      when(invited.membership).thenReturn(Membership.invite);
      when(client.getRoomById('!invited')).thenReturn(invited);

      expect(datasource.getSpace('!room'), isNull);
      expect(datasource.getSpace('!invited'), isNull);
      expect(datasource.getSpace('!unknown'), isNull);
    });

    group('summary', () {
      MockRoom space({JoinRules? joinRules, bool mayAddChildren = false}) {
        final space = MockRoom();
        when(space.id).thenReturn('!s');
        when(space.isSpace).thenReturn(true);
        when(space.membership).thenReturn(Membership.join);
        when(space.summary).thenReturn(RoomSummary.fromJson({}));
        when(space.joinRules).thenReturn(joinRules);
        when(
          space.canChangeStateEvent(EventTypes.SpaceChild),
        ).thenReturn(mayAddChildren);
        when(client.getRoomById('!s')).thenReturn(space);
        return space;
      }

      test('whenPublicAndAllowedToAdd_saysSo', () {
        space(joinRules: JoinRules.public, mayAddChildren: true);

        final summary = datasource.getSpace('!s')!;

        expect(summary.isPublic, isTrue);
        expect(summary.canAddChildren, isTrue);
      });

      test('whenPrivateAndNotAllowedToAdd_saysSo', () {
        space(joinRules: JoinRules.invite);

        final summary = datasource.getSpace('!s')!;

        expect(summary.isPublic, isFalse);
        expect(summary.canAddChildren, isFalse);
      });
    });

    test('whenManagedByABridge_offersNoInvitation', () {
      final space = MockRoom();
      when(space.id).thenReturn('!s');
      when(space.isSpace).thenReturn(true);
      when(space.membership).thenReturn(Membership.join);
      when(space.summary).thenReturn(RoomSummary.fromJson({}));
      when(space.canInvite).thenReturn(true);
      when(space.canonicalAlias).thenReturn('#twake-space-1:own.org');
      when(client.getRoomById('!s')).thenReturn(space);

      expect(datasource.getSpace('!s')!.canInvite, isFalse);
    });

    test('whenNoClient_returnsNothing', () {
      const none = SpaceDatasourceImpl(null);

      expect(none.getSpace('!s'), isNull);
      expect(none.getRoomListEntries(), isEmpty);
      expect(none.getAddableSpaces(), isEmpty);
    });
  });

  group('getAddableSpaces', () {
    MockRoom room(
      String id, {
      bool isSpace = true,
      Membership membership = Membership.join,
      bool mayAdd = true,
    }) {
      final room = MockRoom();
      when(room.id).thenReturn(id);
      when(room.isSpace).thenReturn(isSpace);
      when(room.membership).thenReturn(membership);
      when(room.summary).thenReturn(RoomSummary.fromJson({}));
      when(room.canChangeStateEvent(EventTypes.SpaceChild)).thenReturn(mayAdd);
      return room;
    }

    test('whenSpacesDiffer_keepsTheJoinedOnesTheUserMayAddTo', () {
      final rooms = [
        room('!ok'),
        room('!readOnly', mayAdd: false),
        room('!invited', membership: Membership.invite),
        room('!channel', isSpace: false),
      ];
      when(client.rooms).thenReturn(rooms);

      expect(datasource.getAddableSpaces().map((s) => s.id), ['!ok']);
    });
  });

  group('getSpaceChildren', () {
    void whenHierarchy(List<Map<String, Object?>> children) =>
        when(
          client.getSpaceHierarchy(
            any,
            limit: anyNamed('limit'),
            maxDepth: anyNamed('maxDepth'),
          ),
        ).thenAnswer(
          (_) async => GetSpaceHierarchyResponse.fromJson({
            'rooms': [
              {
                'room_id': '!s',
                'num_joined_members': 1,
                'world_readable': false,
                'guest_can_join': false,
                'children_state': [
                  for (final child in children)
                    {
                      'type': 'm.space.child',
                      'state_key': child['room_id'],
                      'sender': '@a:b',
                      'origin_server_ts': child['ts'] ?? 1,
                      'content': {
                        'via': child['via'] ?? ['b.org'],
                        if (child['order'] != null) 'order': child['order'],
                      },
                    },
                ],
              },
              for (final child in children)
                {
                  'room_id': child['room_id'],
                  'num_joined_members': 2,
                  'world_readable': false,
                  'guest_can_join': false,
                  'join_rule': child['join_rule'],
                  'room_type': child['room_type'],
                  'children_state': [],
                },
            ],
          }),
        );

    test('whenRead_dropsTheSpaceAndKeepsTheSpecOrder', () async {
      whenHierarchy([
        {'room_id': '!late', 'ts': 9},
        {'room_id': '!early', 'ts': 1},
        {'room_id': '!ordered', 'ts': 5, 'order': 'a'},
      ]);

      final children = await datasource.getSpaceChildren('!s');

      expect(children.map((c) => c.roomId), ['!ordered', '!early', '!late']);
    });

    test('whenOrderIsInvalid_countsItAsNone', () async {
      whenHierarchy([
        {'room_id': '!bad', 'order': 'é'},
      ]);

      expect((await datasource.getSpaceChildren('!s')).single.order, isNull);
    });

    test('whenRead_keepsTheViaOfTheSpace', () async {
      whenHierarchy([
        {
          'room_id': '!c',
          'via': ['good.org'],
        },
      ]);

      expect((await datasource.getSpaceChildren('!s')).single.via, [
        'good.org',
      ]);
    });

    test('whenRuleIsPublicOrRestricted_isJoinable', () async {
      whenHierarchy([
        {'room_id': '!public', 'join_rule': 'public'},
        {'room_id': '!restricted', 'join_rule': 'restricted'},
        {'room_id': '!invite', 'join_rule': 'invite'},
      ]);

      final children = await datasource.getSpaceChildren('!s');

      expect(children.where((c) => c.isJoinable).map((c) => c.roomId), [
        '!public',
        '!restricted',
      ]);
    });

    test('whenTheUserIsInSomeOfThem_saysWhich', () async {
      whenHierarchy([
        {'room_id': '!in'},
        {'room_id': '!out'},
        {'room_id': '!invited'},
      ]);
      final joined = _joined();
      when(client.getRoomById('!in')).thenReturn(joined);
      final invited = MockRoom();
      when(invited.membership).thenReturn(Membership.invite);
      when(client.getRoomById('!invited')).thenReturn(invited);

      final children = await datasource.getSpaceChildren('!s');

      expect(children.where((c) => c.isJoined).map((c) => c.roomId), ['!in']);
    });

    test('whenItFails_throwsTyped', () async {
      when(
        client.getSpaceHierarchy(
          any,
          limit: anyNamed('limit'),
          maxDepth: anyNamed('maxDepth'),
        ),
      ).thenThrow(Exception('down'));

      await expectLater(
        datasource.getSpaceChildren('!s'),
        throwsA(isA<SpaceChildrenUnavailableException>()),
      );
    });
  });

  group('joinRoom', () {
    test('whenViaIsGiven_usesIt', () async {
      final joined = _joined();
      when(client.getRoomById('!c')).thenReturn(joined);

      await datasource.joinRoom('!c', via: const ['good.org']);

      verify(client.joinRoom('!c', via: ['good.org'])).called(1);
    });

    test('whenNoVia_usesTheServersOfTheId', () async {
      final joined = _joined();
      when(client.getRoomById('!c:b.org')).thenReturn(joined);

      await datasource.joinRoom('!c:b.org');

      verify(client.joinRoom('!c:b.org', via: ['b.org', 'own.org'])).called(1);
    });

    test('whenTheRoomIsNotSyncedYet_waitsForIt', () async {
      when(client.getRoomById('!c')).thenReturn(null);

      await datasource.joinRoom('!c', via: const ['good.org']);

      verify(client.waitForRoomInSync('!c', join: true)).called(1);
    });

    test('whenTheRoomIsJoined_doesNotWait', () async {
      final joined = _joined();
      when(client.getRoomById('!c')).thenReturn(joined);

      await datasource.joinRoom('!c', via: const ['good.org']);

      verifyNever(client.waitForRoomInSync(any, join: anyNamed('join')));
    });

    test('whenItFails_throwsTyped', () async {
      when(
        client.joinRoom(any, via: anyNamed('via')),
      ).thenThrow(Exception('down'));

      await expectLater(
        datasource.joinRoom('!c'),
        throwsA(isA<SpaceJoinFailedException>()),
      );
    });
  });

  group('watchRoomChanges', () {
    test('whenRoomsFinishLoading_ticks', () async {
      final rooms = Completer<void>();
      when(client.roomsLoading).thenAnswer((_) => rooms.future);
      when(client.onSync).thenReturn(CachedStreamController<SyncUpdate>());
      final ticks = <int>[];
      final subscription = datasource.watchRoomChanges().listen(ticks.add);
      addTearDown(subscription.cancel);
      await pumpEventQueue();
      expect(ticks, isEmpty);

      rooms.complete();
      await pumpEventQueue();

      expect(ticks, [1]);
    });
  });

  group('watchRoomChanges on sync', () {
    late CachedStreamController<SyncUpdate> syncs;
    late List<int> ticks;

    setUp(() async {
      syncs = CachedStreamController<SyncUpdate>();
      when(client.roomsLoading).thenAnswer((_) async {});
      when(client.onSync).thenReturn(syncs);
      ticks = [];
      final subscription = datasource.watchRoomChanges().listen(ticks.add);
      addTearDown(subscription.cancel);
      await pumpEventQueue();
      expect(ticks, [1]);
    });

    Future<void> sync(SyncUpdate update) async {
      syncs.add(update);
      await pumpEventQueue();
    }

    test('whenOnlyAToDeviceEventComes_doesNotTick', () async {
      await sync(
        SyncUpdate(
          nextBatch: 'b',
          toDevice: [
            BasicEventWithSender(
              type: 'm.room_key_request',
              senderId: '@a:b',
              content: {},
            ),
          ],
        ),
      );

      expect(ticks, [1]);
    });

    test('whenAJoinedRoomChanges_ticks', () async {
      await sync(
        SyncUpdate(
          nextBatch: 'b',
          rooms: RoomsUpdate(join: {'!r': JoinedRoomUpdate()}),
        ),
      );

      expect(ticks, [1, 2]);
    });

    test('whenAnInvitationComes_ticks', () async {
      await sync(
        SyncUpdate(
          nextBatch: 'b',
          rooms: RoomsUpdate(invite: {'!r': InvitedRoomUpdate()}),
        ),
      );

      expect(ticks, [1, 2]);
    });

    test('whenARoomIsLeft_ticks', () async {
      await sync(
        SyncUpdate(
          nextBatch: 'b',
          rooms: RoomsUpdate(leave: {'!r': LeftRoomUpdate()}),
        ),
      );

      expect(ticks, [1, 2]);
    });

    test('whenAccountDataChanges_ticks', () async {
      await sync(
        SyncUpdate(
          nextBatch: 'b',
          accountData: [BasicEvent(type: 'm.direct', content: {})],
        ),
      );

      expect(ticks, [1, 2]);
    });

    test('whenSyncsComeInABurst_ticksOnceASecond', () async {
      final room = SyncUpdate(
        nextBatch: 'b',
        rooms: RoomsUpdate(join: {'!r': JoinedRoomUpdate()}),
      );

      await sync(room);
      await sync(room);
      await sync(room);

      expect(ticks, [1, 2]);
    });
  });

  group('open', () {
    test('whenItFails_leavesTheHomeStanding', () async {
      final room = MockRoom();
      when(client.getRoomById('!s')).thenReturn(room);
      when(room.postLoad()).thenThrow(Exception('down'));

      await expectLater(datasource.open('!s'), completes);
    });

    test('whenUnread_marksTheLastEventRead', () async {
      final room = MockRoom();
      when(client.getRoomById('!s')).thenReturn(room);
      when(room.isUnread).thenReturn(true);
      when(room.lastEvent).thenReturn(
        Event(
          type: EventTypes.Message,
          content: {'body': 'hi'},
          eventId: r'$last',
          senderId: '@a:b',
          originServerTs: DateTime(2020),
          room: room,
        ),
      );

      await datasource.open('!s');

      verify(room.setReadMarker(r'$last', mRead: r'$last')).called(1);
    });

    test('whenRead_loadsTheStateOnly', () async {
      final room = MockRoom();
      when(client.getRoomById('!s')).thenReturn(room);
      when(room.isUnread).thenReturn(false);

      await datasource.open('!s');

      verify(room.postLoad()).called(1);
      verifyNever(room.setReadMarker(any, mRead: anyNamed('mRead')));
    });
  });
}

MockRoom _joined() {
  final room = MockRoom();
  when(room.membership).thenReturn(Membership.join);
  return room;
}

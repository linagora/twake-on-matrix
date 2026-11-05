import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/config/feed_config.dart';
import 'package:twake_chat/data/datasource_impl/public_rooms/public_rooms_datasource_impl.dart';
import 'package:twake_chat/domain/exception/public_rooms/public_rooms_exception.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room_preview.dart';

import 'public_rooms_datasource_impl_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Client>(), MockSpec<Room>()])
void main() {
  late MockClient mockClient;
  late PublicRoomsDatasourceImpl datasource;

  PublicRoomsChunk chunk(
    String id, {
    String? name,
    String? roomType,
    String? joinRule,
  }) => PublicRoomsChunk(
    roomId: id,
    name: name,
    roomType: roomType,
    joinRule: joinRule,
    numJoinedMembers: 2,
    guestCanJoin: false,
    worldReadable: false,
  );

  QueryPublicRoomsResponse page(int from, int count, {String? next}) =>
      QueryPublicRoomsResponse(
        chunk: [for (var i = from; i < from + count; i++) chunk('!$i')],
        nextBatch: next,
      );

  /// [answer] gets the `since` token sent and returns a response, its JSON,
  /// or an exception to throw.
  void respond(Object Function(String? since) answer) {
    when(
      mockClient.request(
        RequestType.GET,
        '/client/v3/publicRooms',
        query: anyNamed('query'),
      ),
    ).thenAnswer((invocation) async {
      final query = invocation.namedArguments[#query] as Map<String, Object?>;
      final response = answer(query['since'] as String?);
      if (response is Exception) throw response;
      if (response is QueryPublicRoomsResponse) return response.toJson();
      return response as Map<String, Object?>;
    });
  }

  void stubDirectory(Map<String?, Object> responsesBySince) =>
      respond((since) => responsesBySince[since]!);

  VerificationResult verifyRequests({String? since}) => verify(
    mockClient.request(
      RequestType.GET,
      '/client/v3/publicRooms',
      query: since == null
          ? anyNamed('query')
          : argThat(containsPair('since', since), named: 'query'),
    ),
  );

  Future<List<int>> pageSizes() async {
    final pages = await datasource.fetchDirectory(limit: 1000).toList();
    return pages.map((page) => page.length).toList();
  }

  setUp(() {
    mockClient = MockClient();
    datasource = PublicRoomsDatasourceImpl(mockClient);
  });

  group('fetchDirectory', () {
    test(
      'fetchDirectory_always_readsTheUsersHomeserverPageAfterPage',
      () async {
        // Arrange
        stubDirectory({null: page(0, 100, next: 'p2'), 'p2': page(100, 5)});

        // Act
        final sizes = await pageSizes();

        // Assert
        expect(sizes, [100, 5]);
        verifyNever(
          mockClient.request(
            RequestType.GET,
            any,
            query: argThat(contains('server'), named: 'query'),
          ),
        );
      },
    );

    test('fetchDirectory_whenOverTheLimit_stopsAndCutsAtTheLimit', () async {
      // Arrange
      respond((since) => page(0, 100, next: '${since ?? ''}+'));

      // Act
      final pages = await datasource.fetchDirectory(limit: 250).toList();

      // Assert
      expect(pages.map((page) => page.length), [100, 100, 50]);
      verifyRequests().called(3);
    });

    test('fetchDirectory_whenALaterPageFails_keepsThePagesRead', () async {
      // Arrange
      stubDirectory({
        null: page(0, 100, next: 'p2'),
        'p2': Exception('timeout'),
      });

      // Act
      final sizes = await pageSizes();

      // Assert
      expect(sizes, [100]);
    });

    test('fetchDirectory_whenALaterPageHasNoChunk_keepsThePagesRead', () async {
      // Arrange
      stubDirectory({
        null: page(0, 100, next: 'p2'),
        'p2': <String, Object?>{'next_batch': 'p3'},
      });

      // Act
      final sizes = await pageSizes();

      // Assert
      expect(sizes, [100]);
    });

    test('fetchDirectory_whenTheTokenRepeats_stopsAfterThatPage', () async {
      // Arrange
      stubDirectory({
        null: page(0, 100, next: 'p2'),
        'p2': page(100, 3, next: 'p2'),
      });

      // Act
      final sizes = await pageSizes();

      // Assert
      expect(sizes, [100, 3]);
      verifyRequests(since: 'p2').called(1);
    });

    test('fetchDirectory_whenAPageIsEmptyWithAToken_keepsGoing', () async {
      // Arrange
      stubDirectory({null: page(0, 0, next: 'p2'), 'p2': page(0, 4)});

      // Act
      final sizes = await pageSizes();

      // Assert
      expect(sizes, [0, 4]);
    });

    test('fetchDirectory_whenEmptyPagesNeverEnd_stopsAfterThree', () async {
      // Arrange
      respond((since) => page(0, 0, next: '${since ?? ''}+'));

      // Act
      final sizes = await pageSizes();

      // Assert
      expect(sizes, [0, 0, 0]);
    });

    test('fetchDirectory_whenPagesAreShort_keepsReading', () async {
      // Arrange
      respond((since) {
        final token = since ?? '';
        return page(0, 1, next: token.length < 5 ? '$token+' : null);
      });

      // Act
      final sizes = await pageSizes();

      // Assert
      expect(sizes, hasLength(6));
    });

    test('fetchDirectory_always_skipsRoomsNobodyCanJoin', () async {
      // Arrange
      stubDirectory({
        null: QueryPublicRoomsResponse(
          chunk: [
            chunk('!public', joinRule: 'public'),
            chunk('!unset'),
            chunk('!invite', joinRule: 'invite'),
            chunk('!private', joinRule: 'private'),
            chunk('!knock', joinRule: 'knock'),
          ],
        ),
      });

      // Act
      final rooms = await datasource.fetchDirectory(limit: 1000).first;

      // Assert
      expect(rooms.map((room) => room.roomId), ['!public', '!unset', '!knock']);
    });

    test('fetchDirectory_whenOnlyClosedRoomsCameBeforeAFailure_ends', () async {
      // Arrange
      stubDirectory({
        null: QueryPublicRoomsResponse(
          chunk: [chunk('!invite', joinRule: 'invite')],
          nextBatch: 'p2',
        ),
        'p2': Exception('timeout'),
      });

      // Act
      final sizes = await pageSizes();

      // Assert
      expect(sizes, [0]);
    });

    test('fetchDirectory_whenARoomIsMalformed_skipsOnlyThatRoom', () async {
      // Arrange
      stubDirectory({
        null: {
          'chunk': [
            chunk('!a').toJson(),
            {...chunk('!bad').toJson(), 'avatar_url': 'http://['},
            chunk('!b').toJson(),
          ],
        },
      });

      // Act
      final rooms = await datasource.fetchDirectory(limit: 1000).first;

      // Assert
      expect(rooms.map((room) => room.roomId), ['!a', '!b']);
    });

    test('fetchDirectory_whenPagesListNoRoomForever_stopsAfterThree', () async {
      // Arrange
      respond(
        (since) => QueryPublicRoomsResponse(
          chunk: [chunk('!closed', joinRule: 'invite')],
          nextBatch: '${since ?? ''}+',
        ),
      );

      // Act
      final sizes = await pageSizes();

      // Assert
      expect(sizes, [0, 0, 0]);
    });

    test('fetchDirectory_whenTheFirstPageFails_throwsFetchFailed', () async {
      // Arrange
      stubDirectory({null: Exception('down')});

      // Act
      final result = datasource.fetchDirectory(limit: 1000).toList();

      // Assert
      await expectLater(
        result,
        throwsA(isA<PublicRoomsFetchFailedException>()),
      );
    });

    test(
      'fetchDirectory_whenTheFirstPageHasNoChunk_throwsFetchFailed',
      () async {
        // Arrange
        stubDirectory({null: <String, Object?>{}});

        // Act
        final result = datasource.fetchDirectory(limit: 1000).toList();

        // Assert
        await expectLater(
          result,
          throwsA(isA<PublicRoomsFetchFailedException>()),
        );
      },
    );

    test('fetchDirectory_always_mapsKindAccessAndName', () async {
      // Arrange
      stubDirectory({
        null: QueryPublicRoomsResponse(
          chunk: [
            chunk('!g', name: 'Group'),
            chunk('!f', roomType: FeedConfig.roomType, joinRule: 'knock'),
            chunk('!s', roomType: 'm.space'),
            chunk('!o', roomType: 'org.other', joinRule: 'knock_restricted'),
            chunk('!p', joinRule: 'public'),
            chunk('!r', joinRule: 'restricted'),
            chunk('!u', joinRule: 'org.unknown'),
          ],
        ),
      });

      // Act
      final rooms = await datasource.fetchDirectory(limit: 1000).first;

      // Assert
      expect(rooms.map((room) => room.kind), [
        PublicRoomKind.group,
        PublicRoomKind.feed,
        PublicRoomKind.space,
        PublicRoomKind.other,
        PublicRoomKind.group,
        PublicRoomKind.group,
        PublicRoomKind.group,
      ]);
      expect(rooms.map((room) => room.access), [
        PublicRoomAccess.open,
        PublicRoomAccess.approval,
        PublicRoomAccess.open,
        PublicRoomAccess.approval,
        PublicRoomAccess.open,
        PublicRoomAccess.restricted,
        PublicRoomAccess.restricted,
      ]);
      expect(rooms.first.name, 'Group');
      expect(rooms[1].name, '!f');
    });

    test(
      'fetchDirectory_withASearchTerm_postsTheServerFilterUpToTheLimit',
      () async {
        // Arrange
        when(
          mockClient.request(
            RequestType.POST,
            '/client/v3/publicRooms',
            data: anyNamed('data'),
          ),
        ).thenAnswer((_) async => page(0, 20, next: 'p2').toJson());

        // Act
        final pages = await datasource
            .fetchDirectory(limit: 20, searchTerm: 'équipe')
            .toList();

        // Assert
        expect(pages.map((page) => page.length), [20]);
        verify(
          mockClient.request(
            RequestType.POST,
            '/client/v3/publicRooms',
            data: {
              'limit': 20,
              'filter': {'generic_search_term': 'équipe'},
            },
          ),
        ).called(1);
        verifyNever(
          mockClient.request(RequestType.GET, any, query: anyNamed('query')),
        );
      },
    );

    test(
      'fetchDirectory_withASearchTermWhenTheServerFails_throwsTheTypedException',
      () async {
        // Arrange
        when(
          mockClient.request(
            RequestType.POST,
            '/client/v3/publicRooms',
            data: anyNamed('data'),
          ),
        ).thenThrow(Exception('down'));

        // Act
        final result = datasource
            .fetchDirectory(limit: 20, searchTerm: 'eq')
            .toList();

        // Assert
        await expectLater(
          result,
          throwsA(isA<PublicRoomsFetchFailedException>()),
        );
      },
    );
  });

  test('knownRoomIds_always_listsJoinedAndInvitedRooms', () {
    // Arrange
    final joined = MockRoom();
    when(joined.id).thenReturn('!joined');
    when(joined.membership).thenReturn(Membership.join);
    final invited = MockRoom();
    when(invited.id).thenReturn('!invited');
    when(invited.membership).thenReturn(Membership.invite);
    final left = MockRoom();
    when(left.id).thenReturn('!left');
    when(left.membership).thenReturn(Membership.leave);
    when(mockClient.rooms).thenReturn([joined, invited, left]);

    // Act
    final ids = datasource.getKnownRoomIds();

    // Assert
    expect(ids, {'!joined', '!invited'});
  });

  group('getKnockedRoomIds', () {
    GetRoomSummaryResponse$3 summary(String id, Membership? membership) =>
        GetRoomSummaryResponse$3(
          roomId: id,
          guestCanJoin: false,
          numJoinedMembers: 1,
          worldReadable: false,
          membership: membership,
        );

    test('getKnockedRoomIds_always_keepsOnlyRoomsInKnock', () async {
      // Arrange
      when(
        mockClient.getRoomSummary('!knock'),
      ).thenAnswer((_) async => summary('!knock', Membership.knock));
      when(
        mockClient.getRoomSummary('!none'),
      ).thenAnswer((_) async => summary('!none', null));
      when(
        mockClient.getRoomSummary('!broken'),
      ).thenThrow(MatrixException.fromJson({'errcode': 'M_UNRECOGNIZED'}));

      // Act
      final ids = await datasource.getKnockedRoomIds([
        '!broken',
        '!knock',
        '!none',
      ]);

      // Assert
      expect(ids, {'!knock'});
    });
  });

  test(
    'getKnockedRoomIds_whenASummaryIsMalformed_letsTheErrorThrough',
    () async {
      // Arrange
      when(mockClient.getRoomSummary('!malformed')).thenThrow(TypeError());

      // Act
      final result = datasource.getKnockedRoomIds(['!malformed']);

      // Assert
      await expectLater(result, throwsA(isA<TypeError>()));
    },
  );

  group('join', () {
    test('join_whenTheRoomIsAlreadyInSync_returnsItsId', () async {
      // Arrange
      final room = MockRoom();
      when(room.membership).thenReturn(Membership.join);
      when(mockClient.joinRoom('#a:hs')).thenAnswer((_) async => '!a:hs');
      when(mockClient.getRoomById('!a:hs')).thenReturn(room);

      // Act
      final joined = await datasource.join('#a:hs');

      // Assert
      expect(joined, (roomId: '!a:hs', isInSync: true));
      verifyNever(mockClient.waitForRoomInSync(any, join: anyNamed('join')));
    });

    test('join_whenTheRoomIsNotInSyncYet_waitsForIt', () async {
      // Arrange
      when(mockClient.joinRoom('!a:hs')).thenAnswer((_) async => '!a:hs');
      when(
        mockClient.waitForRoomInSync('!a:hs', join: true),
      ).thenAnswer((_) async => SyncUpdate(nextBatch: 'n'));

      // Act
      final joined = await datasource.join('!a:hs');

      // Assert
      verify(mockClient.waitForRoomInSync('!a:hs', join: true)).called(1);
      expect(joined.isInSync, isTrue);
    });

    test('join_whenWaitingForTheSyncFails_saysItIsNotInSync', () async {
      // Arrange
      when(mockClient.joinRoom('!a:hs')).thenAnswer((_) async => '!a:hs');
      when(
        mockClient.waitForRoomInSync('!a:hs', join: true),
      ).thenThrow(Exception('sync stopped'));

      // Act
      final joined = await datasource.join('!a:hs');

      // Assert
      expect(joined, (roomId: '!a:hs', isInSync: false));
    });

    test('join_whenTheHomeserverRefuses_throwsJoinFailed', () async {
      // Arrange
      when(
        mockClient.joinRoom('!a:hs'),
      ).thenThrow(MatrixException.fromJson({'errcode': 'M_FORBIDDEN'}));

      // Act
      final result = datasource.join('!a:hs');

      // Assert
      await expectLater(result, throwsA(isA<PublicRoomJoinFailedException>()));
    });
    test('join_whenTheRoomNeverReachesTheSync_saysItIsNotInSync', () {
      fakeAsync((async) {
        // Arrange
        when(mockClient.joinRoom('!a:hs')).thenAnswer((_) async => '!a:hs');
        when(
          mockClient.waitForRoomInSync('!a:hs', join: true),
        ).thenAnswer((_) => Completer<SyncUpdate>().future);
        ({String roomId, bool isInSync})? joined;

        // Act
        datasource.join('!a:hs').then((result) => joined = result);
        async.elapse(const Duration(seconds: 31));

        // Assert
        expect(joined, (roomId: '!a:hs', isInSync: false));
      });
    });
  });

  group('knock', () {
    test('knock_always_sendsTheRequest', () async {
      // Arrange
      when(mockClient.knockRoom('!a:hs')).thenAnswer((_) async => '!a:hs');

      // Act
      await datasource.knock('!a:hs');

      // Assert
      verify(mockClient.knockRoom('!a:hs')).called(1);
    });

    test('knock_withServers_routesTheRequestThroughThem', () async {
      // Act
      await datasource.knock('!a:hs', via: const ['hs2']);

      // Assert
      verify(mockClient.knockRoom('!a:hs', via: ['hs2'])).called(1);
    });

    test('knock_whenTheHomeserverRefuses_throwsKnockFailed', () async {
      // Arrange
      when(
        mockClient.knockRoom('!a:hs'),
      ).thenThrow(MatrixException.fromJson({'errcode': 'M_FORBIDDEN'}));

      // Act
      final result = datasource.knock('!a:hs');

      // Assert
      await expectLater(result, throwsA(isA<PublicRoomKnockFailedException>()));
    });
  });

  test('fetchDirectory_withoutClient_throwsNoClient', () async {
    // Act
    final result = const PublicRoomsDatasourceImpl(
      null,
    ).fetchDirectory(limit: 1000).toList();

    // Assert
    await expectLater(result, throwsA(isA<PublicRoomsNoClientException>()));
  });

  group('getPreview', () {
    const alias = '#general:hs';

    GetRoomSummaryResponse$3 summary({
      String? joinRule = 'public',
      Membership? membership,
    }) => GetRoomSummaryResponse$3(
      roomId: '!general:hs',
      name: 'General',
      topic: 'Chat',
      joinRule: joinRule,
      guestCanJoin: false,
      numJoinedMembers: 4,
      worldReadable: false,
      membership: membership,
    );

    void stubSummary(Object answer) {
      final stub = when(mockClient.getRoomSummary(alias, via: anyNamed('via')));
      if (answer is Exception) {
        stub.thenThrow(answer);
      } else {
        stub.thenAnswer((_) async => answer as GetRoomSummaryResponse$3);
      }
    }

    final notFound = MatrixException.fromJson({'errcode': 'M_NOT_FOUND'});

    test('getPreview_whenTheSummaryAnswers_mapsTheRoom', () async {
      // Arrange
      stubSummary(summary(joinRule: 'knock'));

      // Act
      final preview = await datasource.getPreview(alias, via: const []);

      // Assert
      expect(
        preview,
        const PublicRoomPreview.found(
          PublicRoom(
            roomId: '!general:hs',
            name: 'General',
            topic: 'Chat',
            memberCount: 4,
            access: PublicRoomAccess.approval,
            kind: PublicRoomKind.group,
          ),
        ),
      );
    });

    test('getPreview_whenAJoinRequestIsPending_saysItIsRequested', () async {
      // Arrange
      stubSummary(summary(joinRule: 'knock', membership: Membership.knock));

      // Act
      final preview = await datasource.getPreview(alias, via: const []);

      // Assert
      expect(preview, isA<PublicRoomPreviewFound>());
      expect((preview as PublicRoomPreviewFound).isRequested, isTrue);
    });

    MockRoom syncedRoom(Membership membership) {
      final room = MockRoom();
      when(room.membership).thenReturn(membership);
      when(mockClient.getRoomById('!general:hs')).thenReturn(room);
      return room;
    }

    test('getPreview_whenAlreadyJoinedUnderAnotherAlias_saysJoined', () async {
      // Arrange
      syncedRoom(Membership.join);
      stubSummary(summary(membership: Membership.join));

      // Act
      final preview = await datasource.getPreview(alias, via: const []);

      // Assert
      expect(preview, const PublicRoomPreview.joined('!general:hs'));
    });

    test('getPreview_whenInvited_saysJoined', () async {
      // Arrange
      syncedRoom(Membership.invite);
      stubSummary(summary(membership: Membership.invite));

      // Act
      final preview = await datasource.getPreview(alias, via: const []);

      // Assert
      expect(preview, const PublicRoomPreview.joined('!general:hs'));
      verifyNever(
        mockClient.waitForRoomInSync(
          any,
          join: anyNamed('join'),
          invite: anyNamed('invite'),
        ),
      );
    });

    test('getPreview_whenJoinedButNotInSyncYet_waitsForTheRoom', () async {
      // Arrange
      when(
        mockClient.waitForRoomInSync('!general:hs', join: true, invite: false),
      ).thenAnswer((_) async => SyncUpdate(nextBatch: 'n'));
      stubSummary(summary(membership: Membership.join));

      // Act
      final preview = await datasource.getPreview(alias, via: const []);

      // Assert
      expect(preview, const PublicRoomPreview.joined('!general:hs'));
      verify(
        mockClient.waitForRoomInSync('!general:hs', join: true, invite: false),
      ).called(1);
    });

    test('getPreview_whenTheJoinedRoomNeverReachesTheSync_saysUnavailable', () {
      fakeAsync((async) {
        // Arrange
        when(
          mockClient.waitForRoomInSync(
            '!general:hs',
            join: false,
            invite: true,
          ),
        ).thenAnswer((_) => Completer<SyncUpdate>().future);
        stubSummary(summary(membership: Membership.invite));
        PublicRoomPreview? preview;

        // Act
        datasource
            .getPreview(alias, via: const [])
            .then((result) => preview = result);
        async.elapse(const Duration(seconds: 31));

        // Assert
        expect(preview, const PublicRoomPreview.unavailable());
      });
    });

    test(
      'getPreview_whenTheSummaryFailsAndTheLocalRoomWasLeft_saysUnavailable',
      () async {
        // Arrange
        final room = MockRoom();
        when(
          room.requestUser(
            '@me:hs',
            requestState: false,
            requestProfile: false,
          ),
        ).thenAnswer(
          (_) async => User('@me:hs', membership: 'leave', room: room),
        );
        when(mockClient.userID).thenReturn('@me:hs');
        when(mockClient.getRoomByAlias(alias)).thenReturn(room);
        stubSummary(notFound);

        // Act
        final preview = await datasource.getPreview(alias, via: const []);

        // Assert
        expect(preview, const PublicRoomPreview.unavailable());
      },
    );

    test('getPreview_whenTheSummarySaysBanned_saysBanned', () async {
      // Arrange
      stubSummary(summary(membership: Membership.ban));

      // Act
      final preview = await datasource.getPreview(alias, via: const []);

      // Assert
      expect(preview, const PublicRoomPreview.banned());
    });

    MockRoom bannedLocalRoom() {
      final room = MockRoom();
      when(room.membership).thenReturn(Membership.leave);
      when(
        room.requestUser('@me:hs', requestState: false, requestProfile: false),
      ).thenAnswer((_) async => User('@me:hs', membership: 'ban', room: room));
      when(mockClient.userID).thenReturn('@me:hs');
      when(mockClient.getRoomByAlias(alias)).thenReturn(room);
      return room;
    }

    test(
      'getPreview_whenTheSummaryFailsAndTheLocalRoomHasABan_saysBanned',
      () async {
        // Arrange
        bannedLocalRoom();
        stubSummary(notFound);

        // Act
        final preview = await datasource.getPreview(alias, via: const []);

        // Assert
        expect(preview, const PublicRoomPreview.banned());
      },
    );

    test(
      'getPreview_whenTheSummaryFailsWhileRoomsLoad_waitsForTheStoredBan',
      () async {
        // Arrange
        final room = bannedLocalRoom();
        final roomsLoading = Completer<void>();
        when(mockClient.roomsLoading).thenAnswer((_) => roomsLoading.future);
        when(mockClient.getRoomByAlias(alias)).thenReturn(null);
        stubSummary(notFound);

        // Act
        final preview = datasource.getPreview(alias, via: const []);
        await pumpEventQueue();
        when(mockClient.getRoomByAlias(alias)).thenReturn(room);
        roomsLoading.complete();

        // Assert
        expect(await preview, const PublicRoomPreview.banned());
      },
    );

    test(
      'getPreview_whenTheSummaryAnswersOverAStoredBan_followsTheSummary',
      () async {
        // Arrange
        bannedLocalRoom();
        stubSummary(summary(membership: Membership.leave));

        // Act
        final preview = await datasource.getPreview(alias, via: const []);

        // Assert
        expect(preview, isA<PublicRoomPreviewFound>());
      },
    );

    test('getPreview_whenTheRoomIsInviteOnly_saysUnavailable', () async {
      // Arrange
      stubSummary(summary(joinRule: 'invite'));

      // Act
      final preview = await datasource.getPreview(alias, via: const []);

      // Assert
      expect(preview, const PublicRoomPreview.unavailable());
    });

    test('getPreview_whenTheSummarySaysNotFound_saysUnavailable', () async {
      // Arrange
      stubSummary(notFound);

      // Act
      final preview = await datasource.getPreview(alias, via: const []);

      // Assert
      expect(preview, const PublicRoomPreview.unavailable());
    });

    test('getPreview_whenTheServerIsUnreachable_saysUnavailable', () async {
      // Arrange
      stubSummary(Exception('offline'));

      // Act
      final preview = await datasource.getPreview(alias, via: const []);

      // Assert
      expect(preview, const PublicRoomPreview.unavailable());
    });

    test('getPreview_withServers_asksTheSummaryThroughThem', () async {
      // Arrange
      when(
        mockClient.getRoomSummary('!a:hs', via: ['hs2']),
      ).thenThrow(notFound);

      // Act
      await datasource.getPreview('!a:hs', via: const ['hs2']);

      // Assert
      verify(mockClient.getRoomSummary('!a:hs', via: ['hs2'])).called(1);
    });
  });
}

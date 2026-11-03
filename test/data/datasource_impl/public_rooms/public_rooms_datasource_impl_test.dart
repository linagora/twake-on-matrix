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

  void stubDirectory(Map<String?, Object> responsesBySince) {
    responsesBySince.forEach((since, response) {
      final call = when(mockClient.queryPublicRooms(limit: 100, since: since));
      if (response is Exception) {
        call.thenThrow(response);
      } else {
        call.thenAnswer((_) async => response as QueryPublicRoomsResponse);
      }
    });
  }

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
        verifyNever(mockClient.queryPublicRooms(server: anyNamed('server')));
      },
    );

    test('fetchDirectory_whenOverTheLimit_stopsAndCutsAtTheLimit', () async {
      // Arrange
      when(
        mockClient.queryPublicRooms(limit: 100, since: anyNamed('since')),
      ).thenAnswer(
        (invocation) async =>
            page(0, 100, next: '${invocation.namedArguments[#since] ?? ''}+'),
      );

      // Act
      final pages = await datasource.fetchDirectory(limit: 250).toList();

      // Assert
      expect(pages.map((page) => page.length), [100, 100, 50]);
      verify(
        mockClient.queryPublicRooms(limit: 100, since: anyNamed('since')),
      ).called(3);
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
      verify(mockClient.queryPublicRooms(limit: 100, since: 'p2')).called(1);
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
      when(
        mockClient.queryPublicRooms(limit: 100, since: anyNamed('since')),
      ).thenAnswer(
        (invocation) async =>
            page(0, 0, next: '${invocation.namedArguments[#since] ?? ''}+'),
      );

      // Act
      final sizes = await pageSizes();

      // Assert
      expect(sizes, [0, 0, 0]);
    });

    test('fetchDirectory_whenPagesAreShort_keepsReading', () async {
      // Arrange
      when(
        mockClient.queryPublicRooms(limit: 100, since: anyNamed('since')),
      ).thenAnswer((invocation) async {
        final since = invocation.namedArguments[#since] as String? ?? '';
        return page(0, 1, next: since.length < 5 ? '$since+' : null);
      });

      // Act
      final sizes = await pageSizes();

      // Assert
      expect(sizes, hasLength(6));
    });

    test('fetchDirectory_always_skipsRoomsNobodyCanJoin', () async {
      // Arrange
      when(mockClient.queryPublicRooms(limit: 100, since: null)).thenAnswer(
        (_) async => QueryPublicRoomsResponse(
          chunk: [
            chunk('!public', joinRule: 'public'),
            chunk('!unset'),
            chunk('!invite', joinRule: 'invite'),
            chunk('!private', joinRule: 'private'),
            chunk('!knock', joinRule: 'knock'),
          ],
        ),
      );

      // Act
      final rooms = await datasource.fetchDirectory(limit: 1000).first;

      // Assert
      expect(rooms.map((room) => room.roomId), ['!public', '!unset', '!knock']);
    });

    test('fetchDirectory_whenTheFirstPageFails_throwsFetchFailed', () async {
      // Arrange
      when(
        mockClient.queryPublicRooms(limit: 100, since: null),
      ).thenThrow(Exception('down'));

      // Act
      final result = datasource.fetchDirectory(limit: 1000).toList();

      // Assert
      await expectLater(
        result,
        throwsA(isA<PublicRoomsFetchFailedException>()),
      );
    });

    test('fetchDirectory_always_mapsKindAccessAndName', () async {
      // Arrange
      when(mockClient.queryPublicRooms(limit: 100, since: null)).thenAnswer(
        (_) async => QueryPublicRoomsResponse(
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
      );

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
  });

  test('memberRoomIds_always_listsJoinedAndInvitedRooms', () {
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
    final ids = datasource.getMemberRoomIds();

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
}

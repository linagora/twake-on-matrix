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

  setUp(() {
    mockClient = MockClient();
    datasource = PublicRoomsDatasourceImpl(mockClient);
  });

  group('fetchDirectory', () {
    test(
      'fetchDirectory_always_readsTheUsersHomeserverPageAfterPage',
      () async {
        // Arrange
        when(
          mockClient.queryPublicRooms(limit: 100, since: null),
        ).thenAnswer((_) async => page(0, 100, next: 'p2'));
        when(
          mockClient.queryPublicRooms(limit: 100, since: 'p2'),
        ).thenAnswer((_) async => page(100, 5));

        // Act
        final rooms = await datasource.fetchDirectory(limit: 1000);

        // Assert
        expect(rooms, hasLength(105));
        verifyNever(mockClient.queryPublicRooms(server: anyNamed('server')));
      },
    );

    test('fetchDirectory_whenOverTheLimit_stopsAndCutsAtTheLimit', () async {
      // Arrange
      when(
        mockClient.queryPublicRooms(limit: 100, since: anyNamed('since')),
      ).thenAnswer((_) async => page(0, 100, next: 'more'));

      // Act
      final rooms = await datasource.fetchDirectory(limit: 250);

      // Assert
      expect(rooms, hasLength(250));
      verify(
        mockClient.queryPublicRooms(limit: 100, since: anyNamed('since')),
      ).called(3);
    });

    test('fetchDirectory_whenALaterPageFails_keepsThePagesRead', () async {
      // Arrange
      when(
        mockClient.queryPublicRooms(limit: 100, since: null),
      ).thenAnswer((_) async => page(0, 100, next: 'p2'));
      when(
        mockClient.queryPublicRooms(limit: 100, since: 'p2'),
      ).thenThrow(Exception('timeout'));

      // Act
      final rooms = await datasource.fetchDirectory(limit: 1000);

      // Assert
      expect(rooms, hasLength(100));
    });

    test('fetchDirectory_whenTheFirstPageFails_throwsFetchFailed', () async {
      // Arrange
      when(
        mockClient.queryPublicRooms(limit: 100, since: null),
      ).thenThrow(Exception('down'));

      // Act
      final result = datasource.fetchDirectory(limit: 1000);

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
          ],
        ),
      );

      // Act
      final rooms = await datasource.fetchDirectory(limit: 1000);

      // Assert
      expect(rooms.map((room) => room.kind), [
        PublicRoomKind.group,
        PublicRoomKind.feed,
        PublicRoomKind.space,
        PublicRoomKind.other,
      ]);
      expect(rooms.map((room) => room.access), [
        PublicRoomAccess.open,
        PublicRoomAccess.approval,
        PublicRoomAccess.open,
        PublicRoomAccess.approval,
      ]);
      expect(rooms.first.name, 'Group');
      expect(rooms[1].name, '!f');
    });
  });

  test('joinedRoomIds_always_listsOnlyJoinedRooms', () {
    // Arrange
    final joined = MockRoom();
    when(joined.id).thenReturn('!joined');
    when(joined.membership).thenReturn(Membership.join);
    final invited = MockRoom();
    when(invited.id).thenReturn('!invited');
    when(invited.membership).thenReturn(Membership.invite);
    when(mockClient.rooms).thenReturn([joined, invited]);

    // Act
    final ids = datasource.getJoinedRoomIds();

    // Assert
    expect(ids, {'!joined'});
  });

  group('join', () {
    test('join_whenTheRoomIsAlreadyInSync_returnsItsId', () async {
      // Arrange
      final room = MockRoom();
      when(room.membership).thenReturn(Membership.join);
      when(mockClient.joinRoom('#a:hs')).thenAnswer((_) async => '!a:hs');
      when(mockClient.getRoomById('!a:hs')).thenReturn(room);

      // Act
      final roomId = await datasource.join('#a:hs');

      // Assert
      expect(roomId, '!a:hs');
      verifyNever(mockClient.waitForRoomInSync(any, join: anyNamed('join')));
    });

    test('join_whenTheRoomIsNotInSyncYet_waitsForIt', () async {
      // Arrange
      when(mockClient.joinRoom('!a:hs')).thenAnswer((_) async => '!a:hs');
      when(
        mockClient.waitForRoomInSync('!a:hs', join: true),
      ).thenAnswer((_) async => SyncUpdate(nextBatch: 'n'));

      // Act
      await datasource.join('!a:hs');

      // Assert
      verify(mockClient.waitForRoomInSync('!a:hs', join: true)).called(1);
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
    test('join_whenTheRoomNeverReachesTheSync_stillReturnsItsId', () {
      fakeAsync((async) {
        // Arrange
        when(mockClient.joinRoom('!a:hs')).thenAnswer((_) async => '!a:hs');
        when(
          mockClient.waitForRoomInSync('!a:hs', join: true),
        ).thenAnswer((_) => Completer<SyncUpdate>().future);
        String? roomId;

        // Act
        datasource.join('!a:hs').then((id) => roomId = id);
        async.elapse(const Duration(seconds: 31));

        // Assert
        expect(roomId, '!a:hs');
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
    ).fetchDirectory(limit: 1000);

    // Assert
    await expectLater(result, throwsA(isA<PublicRoomsNoClientException>()));
  });
}

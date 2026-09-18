import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/config/feed_config.dart';
import 'package:twake_chat/data/datasource_impl/feed/feed_datasource_impl.dart';
import 'package:twake_chat/domain/exception/feed/feed_exception.dart';

import 'feed_datasource_impl_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Client>(), MockSpec<Room>()])
void main() {
  late MockClient mockClient;
  late FeedDatasourceImpl datasource;

  const testRoomId = '!feed:example.com';

  final sharedHistoryEvent = StateEvent(
    type: EventTypes.HistoryVisibility,
    content: {'history_visibility': HistoryVisibility.shared.name},
    stateKey: '',
  ).toJson();

  PostExpectation<Future<Map<String, Object?>>> whenCreateRoom() => when(
    mockClient.request(
      any,
      any,
      data: anyNamed('data'),
      contentType: anyNamed('contentType'),
      query: anyNamed('query'),
    ),
  );

  Map<String, dynamic> captureRequestBody() {
    return verify(
          mockClient.request(
            RequestType.POST,
            '/client/v3/createRoom',
            data: captureAnyNamed('data'),
            contentType: anyNamed('contentType'),
            query: anyNamed('query'),
          ),
        ).captured.single
        as Map<String, dynamic>;
  }

  setUp(() {
    mockClient = MockClient();
    datasource = FeedDatasourceImpl(mockClient);

    whenCreateRoom().thenAnswer((_) async => {'room_id': testRoomId});
    when(mockClient.getRoomById(testRoomId)).thenReturn(MockRoom());
  });

  group('FeedDatasourceImpl.createFeed', () {
    test('createFeed_always_sendsTheFeedPreset', () async {
      // Act
      await datasource.createFeed(name: 'Announcements');

      // Assert
      expect(captureRequestBody()['preset'], equals(FeedConfig.preset));
    });

    test('createFeed_always_sendsTheFeedRoomTypeInCreationContent', () async {
      // Act
      await datasource.createFeed(name: 'Announcements');

      // Assert
      expect(
        captureRequestBody()['creation_content'],
        equals({'type': FeedConfig.roomType}),
        reason:
            'Without m.room.type in creation_content the room is created as a '
            'plain group and can never be told apart from one.',
      );
    });

    test('createFeed_whenGivenAName_forwardsIt', () async {
      // Act
      await datasource.createFeed(name: 'Announcements');

      // Assert
      expect(captureRequestBody()['name'], equals('Announcements'));
    });

    test('createFeed_whenGivenNoName_omitsTheNameKey', () async {
      // Act
      await datasource.createFeed();

      // Assert
      expect(captureRequestBody().containsKey('name'), isFalse);
    });

    test('createFeed_whenGivenAnAvatar_sendsItWithASharedHistory', () async {
      // Act
      await datasource.createFeed(avatarUrl: 'mxc://example.com/avatar');

      // Assert
      expect(
        captureRequestBody()['initial_state'],
        equals([
          StateEvent(
            type: EventTypes.RoomAvatar,
            content: {'url': 'mxc://example.com/avatar'},
            stateKey: '',
          ).toJson(),
          sharedHistoryEvent,
        ]),
      );
    });

    test('createFeed_whenGivenNoAvatar_onlySendsASharedHistory', () async {
      // Act
      await datasource.createFeed(name: 'Announcements');

      // Assert
      expect(
        captureRequestBody()['initial_state'],
        equals([sharedHistoryEvent]),
      );
    });

    test('createFeed_whenRoomAlreadyInSync_doesNotWaitForSync', () async {
      // Act
      final roomId = await datasource.createFeed(name: 'Announcements');

      // Assert
      expect(roomId, equals(testRoomId));
      verifyNever(mockClient.waitForRoomInSync(any, join: anyNamed('join')));
    });

    test('createFeed_whenRoomNotInSyncYet_waitsForIt', () async {
      // Arrange
      when(mockClient.getRoomById(testRoomId)).thenReturn(null);

      // Act
      await datasource.createFeed(name: 'Announcements');

      // Assert
      verify(mockClient.waitForRoomInSync(testRoomId, join: true)).called(1);
    });

    test(
      'createFeed_whenPresetIsRejectedByTheHomeserver_throwsFeedNotSupported',
      () async {
        // Arrange — verbatim response of an unpatched Synapse, from
        // synapse/handlers/room.py::_room_preset_config
        whenCreateRoom().thenThrow(
          MatrixException.fromJson({
            'errcode': 'M_BAD_JSON',
            'error': "'${FeedConfig.preset}' is not a valid preset",
          }),
        );

        // Act
        final creation = datasource.createFeed(name: 'Announcements');

        // Assert
        await expectLater(
          creation,
          throwsA(isA<FeedNotSupportedByHomeserverException>()),
        );
      },
    );

    test(
      'createFeed_whenPresetRejectionIsReworded_stillThrowsFeedNotSupported',
      () async {
        // Arrange
        whenCreateRoom().thenThrow(
          MatrixException.fromJson({
            'errcode': 'M_BAD_JSON',
            'error': 'Unknown room creation option',
          }),
        );

        // Act
        final creation = datasource.createFeed(name: 'Announcements');

        // Assert
        await expectLater(
          creation,
          throwsA(isA<FeedNotSupportedByHomeserverException>()),
        );
      },
    );

    test(
      'createFeed_whenCreationFailsForAnotherReason_throwsFeedCreationFailed',
      () async {
        // Arrange
        final serverError = MatrixException.fromJson({
          'errcode': 'M_LIMIT_EXCEEDED',
          'error': 'Too many requests',
        });
        whenCreateRoom().thenThrow(serverError);

        // Act
        final creation = datasource.createFeed(name: 'Announcements');

        // Assert
        await expectLater(
          creation,
          throwsA(
            isA<FeedCreationFailedException>().having(
              (exception) => exception.cause,
              'cause',
              same(serverError),
            ),
          ),
        );
      },
    );

    test(
      'createFeed_whenResponseHasNoRoomId_throwsFeedCreationFailed',
      () async {
        // Arrange
        whenCreateRoom().thenAnswer((_) async => <String, Object?>{});

        // Act
        final creation = datasource.createFeed(name: 'Announcements');

        // Assert
        await expectLater(
          creation,
          throwsA(isA<FeedCreationFailedException>()),
        );
      },
    );

    test(
      'createFeed_whenWaitingForTheSyncFails_throwsFeedCreationFailed',
      () async {
        // Arrange
        final syncError = Exception('Sync stopped');
        when(mockClient.getRoomById(testRoomId)).thenReturn(null);
        when(
          mockClient.waitForRoomInSync(testRoomId, join: true),
        ).thenThrow(syncError);

        // Act
        final creation = datasource.createFeed(name: 'Announcements');

        // Assert
        await expectLater(
          creation,
          throwsA(
            isA<FeedCreationFailedException>().having(
              (exception) => exception.cause,
              'cause',
              same(syncError),
            ),
          ),
        );
      },
    );
  });
}

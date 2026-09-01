import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/config/feed_config.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/client_feed_extension.dart';

import 'client_feed_extension_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Client>(), MockSpec<Room>()])
void main() {
  late MockClient mockClient;
  late MockRoom mockRoom;

  const testRoomId = '!feed:example.com';

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
    mockRoom = MockRoom();

    when(
      mockClient.request(
        any,
        any,
        data: anyNamed('data'),
        contentType: anyNamed('contentType'),
        query: anyNamed('query'),
      ),
    ).thenAnswer((_) async => {'room_id': testRoomId});
    when(mockClient.getRoomById(testRoomId)).thenReturn(mockRoom);
  });

  group('ClientFeedExtension.createFeedRoom', () {
    test('createFeedRoom_always_sendsTheFeedPreset', () async {
      // Act
      await mockClient.createFeedRoom(feedName: 'Announcements');

      // Assert
      expect(captureRequestBody()['preset'], equals(FeedConfig.preset));
    });

    test(
      'createFeedRoom_always_sendsTheFeedRoomTypeInCreationContent',
      () async {
        // Act
        await mockClient.createFeedRoom(feedName: 'Announcements');

        // Assert
        expect(
          captureRequestBody()['creation_content'],
          equals({'type': FeedConfig.roomType}),
          reason:
              'Without m.room.type in creation_content the room is created as a '
              'plain group and Room.isFeed can never be true.',
        );
      },
    );

    test('createFeedRoom_whenGivenAName_forwardsIt', () async {
      // Act
      await mockClient.createFeedRoom(feedName: 'Announcements');

      // Assert
      expect(captureRequestBody()['name'], equals('Announcements'));
    });

    test('createFeedRoom_whenGivenNoName_omitsTheNameKey', () async {
      // Act
      await mockClient.createFeedRoom();

      // Assert
      expect(captureRequestBody().containsKey('name'), isFalse);
    });

    test(
      'createFeedRoom_whenGivenPowerLevels_forwardsThemAsOverride',
      () async {
        // Arrange
        const powerLevels = {'events_default': 80};

        // Act
        await mockClient.createFeedRoom(powerLevelContentOverride: powerLevels);

        // Assert
        expect(
          captureRequestBody()['power_level_content_override'],
          equals(powerLevels),
        );
      },
    );

    test('createFeedRoom_whenGivenInitialState_serialisesIt', () async {
      // Arrange
      final stateEvent = StateEvent(
        type: EventTypes.RoomAvatar,
        content: {'url': 'mxc://example.com/avatar'},
        stateKey: '',
      );

      // Act
      await mockClient.createFeedRoom(initialState: [stateEvent]);

      // Assert
      expect(
        captureRequestBody()['initial_state'],
        equals([stateEvent.toJson()]),
      );
    });

    test('createFeedRoom_whenRoomAlreadyInSync_doesNotWaitForSync', () async {
      // Act
      final roomId = await mockClient.createFeedRoom(feedName: 'Announcements');

      // Assert
      expect(roomId, equals(testRoomId));
      verifyNever(mockClient.waitForRoomInSync(any, join: anyNamed('join')));
    });

    test('createFeedRoom_whenRoomNotInSyncYet_waitsForIt', () async {
      // Arrange
      when(mockClient.getRoomById(testRoomId)).thenReturn(null);

      // Act
      await mockClient.createFeedRoom(feedName: 'Announcements');

      // Assert
      verify(mockClient.waitForRoomInSync(testRoomId, join: true)).called(1);
    });
  });
}

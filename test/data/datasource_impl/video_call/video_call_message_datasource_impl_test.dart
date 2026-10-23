import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/datasource_impl/video_call/video_call_message_datasource_impl.dart';

import 'video_call_message_datasource_impl_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Client>(), MockSpec<Room>()])
void main() {
  late MockClient mockClient;
  late VideoCallMessageDatasourceImpl datasource;

  const testRoomUrl = 'https://meet.example.com/abc-defg-hij';
  const testRoomId = '!room:example.com';

  setUp(() {
    mockClient = MockClient();
    datasource = VideoCallMessageDatasourceImpl(mockClient);
  });

  group('VideoCallMessageDatasourceImpl.isJoined', () {
    for (final (name, membership, expected) in [
      ('Joined', Membership.join, true),
      ('Left', Membership.leave, false),
      ('Banned', Membership.ban, false),
    ]) {
      test('isJoined_whenRoomIs${name}_returns$expected', () {
        // Arrange
        final mockRoom = MockRoom();
        when(mockRoom.membership).thenReturn(membership);
        when(mockClient.getRoomById(testRoomId)).thenReturn(mockRoom);

        // Act
        final joined = datasource.isJoined(testRoomId);

        // Assert
        expect(joined, equals(expected));
      });
    }

    test('isJoined_whenRoomIsUnknown_returnsFalse', () {
      // Arrange
      when(mockClient.getRoomById(testRoomId)).thenReturn(null);

      // Act
      final joined = datasource.isJoined(testRoomId);

      // Assert
      expect(joined, isFalse);
    });
  });

  group('VideoCallMessageDatasourceImpl.sendCallMessage', () {
    test('sendCallMessage_always_sendsTheCallMessageToTheRoom', () async {
      // Arrange
      final mockRoom = MockRoom();
      when(mockClient.getRoomById(testRoomId)).thenReturn(mockRoom);

      // Act
      await datasource.sendCallMessage(
        roomId: testRoomId,
        url: testRoomUrl,
        body: 'Has started a video call $testRoomUrl',
      );

      // Assert
      verify(
        mockRoom.sendEvent({
          'msgtype': 'm.text',
          'body': 'Has started a video call $testRoomUrl',
          'call_url': testRoomUrl,
        }),
      ).called(1);
    });

    test('sendCallMessage_whenRoomIsUnknown_sendsNothing', () async {
      // Arrange
      when(mockClient.getRoomById(testRoomId)).thenReturn(null);

      // Act
      final sending = datasource.sendCallMessage(
        roomId: testRoomId,
        url: testRoomUrl,
        body: 'Has started a video call $testRoomUrl',
      );

      // Assert
      await expectLater(sending, completes);
    });
  });
}

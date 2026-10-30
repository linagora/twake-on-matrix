import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/datasource_impl/forward/forward_datasource_impl.dart';

import 'forward_datasource_impl_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Client>(), MockSpec<Room>()])
void main() {
  const testRoomId = '!room:example.com';
  const testContent = {'msgtype': 'm.text', 'body': 'hello'};

  late MockClient mockClient;
  late ForwardDatasourceImpl datasource;

  setUp(() {
    mockClient = MockClient();
    datasource = ForwardDatasourceImpl(mockClient);
  });

  group('ForwardDatasourceImpl.isJoined', () {
    for (final (name, membership, expected) in [
      ('Joined', Membership.join, true),
      ('Left', Membership.leave, false),
      ('Invited', Membership.invite, false),
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
      when(mockClient.getRoomById(testRoomId)).thenReturn(null);

      expect(datasource.isJoined(testRoomId), isFalse);
    });

    test('isJoined_whenNoClient_returnsFalse', () {
      expect(const ForwardDatasourceImpl(null).isJoined(testRoomId), isFalse);
    });
  });

  group('ForwardDatasourceImpl.sendMessage', () {
    test('sendMessage_whenRoomExists_sendsTheContent', () async {
      // Arrange
      final mockRoom = MockRoom();
      when(mockClient.getRoomById(testRoomId)).thenReturn(mockRoom);

      // Act
      await datasource.sendMessage(roomId: testRoomId, content: testContent);

      // Assert
      verify(mockRoom.sendEvent(testContent)).called(1);
    });

    test('sendMessage_whenRoomIsUnknown_throws', () async {
      when(mockClient.getRoomById(testRoomId)).thenReturn(null);

      await expectLater(
        datasource.sendMessage(roomId: testRoomId, content: testContent),
        throwsStateError,
      );
    });

    test('sendMessage_whenSendFails_rethrows', () async {
      // Arrange
      final mockRoom = MockRoom();
      when(mockClient.getRoomById(testRoomId)).thenReturn(mockRoom);
      when(mockRoom.sendEvent(testContent)).thenThrow(Exception('network'));

      // Act & Assert
      await expectLater(
        datasource.sendMessage(roomId: testRoomId, content: testContent),
        throwsException,
      );
    });
  });
}

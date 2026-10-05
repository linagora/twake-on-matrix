import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/datasource/video_call/video_call_message_datasource.dart';
import 'package:twake_chat/data/datasource/video_call/video_call_room_datasource.dart';
import 'package:twake_chat/data/model/video_call/create_video_call_room_response.dart';
import 'package:twake_chat/data/repository/video_call/video_call_repository_impl.dart';
import 'package:twake_chat/domain/exception/video_call/video_call_exception.dart';
import 'package:twake_chat/domain/services/video_call/video_call_slug_service.dart';

import 'video_call_repository_impl_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<VideoCallRoomDatasource>(),
  MockSpec<VideoCallMessageDatasource>(),
])
void main() {
  late MockVideoCallRoomDatasource mockRoomDatasource;
  late MockVideoCallMessageDatasource mockMessageDatasource;
  late VideoCallRepositoryImpl repository;

  void givenCreatedRoom({String? url}) => when(
    mockRoomDatasource.createRoom(),
  ).thenAnswer((_) async => CreateVideoCallRoomResponse(url: url));

  setUp(() {
    mockRoomDatasource = MockVideoCallRoomDatasource();
    mockMessageDatasource = MockVideoCallMessageDatasource();
    repository = VideoCallRepositoryImpl(
      roomDatasource: mockRoomDatasource,
      messageDatasource: mockMessageDatasource,
      slugService: VideoCallSlugService(),
    );
  });

  group('VideoCallRepositoryImpl', () {
    test('createRoom_whenRoomIsCreated_returnsItsSlug', () async {
      // Arrange
      givenCreatedRoom(url: 'https://meet.example.com/abc-defg-hij');

      // Act
      final slug = await repository.createRoom();

      // Assert
      expect(slug, equals('abc-defg-hij'));
    });

    test('createRoom_whenResponseHasNoUrl_throwsCreationFailed', () async {
      // Arrange
      givenCreatedRoom();

      // Act
      final creation = repository.createRoom();

      // Assert
      await expectLater(
        creation,
        throwsA(isA<VideoCallRoomCreationFailedException>()),
      );
    });

    test('createRoom_whenRoomUrlHasNoSlug_throwsCreationFailed', () async {
      // Arrange
      givenCreatedRoom(
        url: 'https://meet.example.com/6f1c2d3e-0000-4000-8000-000000000000',
      );

      // Act
      final creation = repository.createRoom();

      // Assert
      await expectLater(
        creation,
        throwsA(isA<VideoCallRoomCreationFailedException>()),
      );
    });

    test('createRoom_whenTheDatasourceThrows_rethrows', () async {
      // Arrange
      when(mockRoomDatasource.createRoom()).thenAnswer(
        (_) => Future.error(const VideoCallRoomCreationUnavailableException()),
      );

      // Act
      final creation = repository.createRoom();

      // Assert
      await expectLater(
        creation,
        throwsA(isA<VideoCallRoomCreationUnavailableException>()),
      );
    });

    test('sendCallMessage_always_delegatesToTheDatasource', () async {
      // Act
      await repository.sendCallMessage(
        roomId: '!room:example.com',
        url: 'https://meet.example.com/abc-defg-hij',
        body: 'Has started a video call',
      );

      // Assert
      verify(
        mockMessageDatasource.sendCallMessage(
          roomId: '!room:example.com',
          url: 'https://meet.example.com/abc-defg-hij',
          body: 'Has started a video call',
        ),
      ).called(1);
    });
  });
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/exception/video_call/video_call_exception.dart';
import 'package:twake_chat/domain/repository/video_call/video_call_repository.dart';
import 'package:twake_chat/domain/services/video_call/video_call_slug_service.dart';
import 'package:twake_chat/domain/video_call/usecases/start_video_call_usecase.dart';
import 'package:twake_chat/utils/voip/video_call_helper.dart';

import 'start_video_call_usecase_test.mocks.dart';

@GenerateNiceMocks([MockSpec<VideoCallRepository>(), MockSpec<Room>()])
void main() {
  late MockVideoCallRepository mockVideoCallRepository;
  late StartVideoCallUseCase useCase;

  const testRoomId = '!room:example.com';
  const baseUrl = 'https://meet.example.com';
  const startedTitle = 'Has started a video call';

  Future<void> execute() => useCase.execute(
    roomId: testRoomId,
    baseUrl: baseUrl,
    startedTitle: startedTitle,
  );

  String captureSentUrl() {
    final captured = verify(
      mockVideoCallRepository.sendCallMessage(
        roomId: testRoomId,
        url: captureAnyNamed('url'),
        body: captureAnyNamed('body'),
      ),
    ).captured;
    final url = captured.first as String;
    expect(captured.last, equals('$startedTitle $url'));
    return url;
  }

  void verifyNothingIsSent() => verifyNever(
    mockVideoCallRepository.sendCallMessage(
      roomId: anyNamed('roomId'),
      url: anyNamed('url'),
      body: anyNamed('body'),
    ),
  );

  setUp(() {
    mockVideoCallRepository = MockVideoCallRepository();
    useCase = StartVideoCallUseCase(
      mockVideoCallRepository,
      VideoCallSlugService(),
    );
    when(mockVideoCallRepository.isJoined(testRoomId)).thenReturn(true);
  });

  void givenCreatedRoom(String url) =>
      when(mockVideoCallRepository.createRoom()).thenAnswer((_) async => url);

  group('StartVideoCallUseCase', () {
    test('execute_whenRoomIsCreated_sendsItsLinkBuiltOnTheBaseUrl', () async {
      // Arrange
      givenCreatedRoom('$baseUrl/abc-defg-hij');

      // Act
      await execute();

      // Assert
      expect(captureSentUrl(), equals('$baseUrl/abc-defg-hij'));
    });

    test(
      'execute_whenRoomCreationIsUnavailable_sendsALocallyGeneratedLink',
      () async {
        // Arrange
        when(mockVideoCallRepository.createRoom()).thenAnswer(
          (_) =>
              Future.error(const VideoCallRoomCreationUnavailableException()),
        );

        // Act
        await execute();

        // Assert
        final url = captureSentUrl();
        final event = Event(
          content: {
            'msgtype': MessageTypes.Text,
            'body': '$startedTitle $url',
            VideoCallHelper.callUrlKey: url,
          },
          type: EventTypes.Message,
          eventId: '\$evt:example.com',
          senderId: '@alice:example.com',
          originServerTs: DateTime.fromMillisecondsSinceEpoch(0),
          room: MockRoom(),
        );
        expect(VideoCallHelper.extractUrl(event, baseUrl), equals(url));
      },
    );

    test('execute_whenRoomCreationFails_throwsAndSendsNothing', () async {
      // Arrange
      when(mockVideoCallRepository.createRoom()).thenAnswer(
        (_) => Future.error(
          VideoCallRoomCreationFailedException(cause: Exception('502')),
        ),
      );

      // Act
      final start = execute();

      // Assert
      await expectLater(
        start,
        throwsA(isA<VideoCallRoomCreationFailedException>()),
      );
      verifyNothingIsSent();
    });

    for (final (name, roomUrl) in [
      ('HasATrailingSlash', '$baseUrl/abc-defg-hij/'),
      ('HasAQuery', '$baseUrl/abc-defg-hij?lang=en'),
    ]) {
      test('execute_whenRoomUrl${name}_sendsItsSlugOnTheBaseUrl', () async {
        // Arrange
        givenCreatedRoom(roomUrl);

        // Act
        await execute();

        // Assert
        expect(captureSentUrl(), equals('$baseUrl/abc-defg-hij'));
      });
    }

    for (final (name, roomUrl) in [
      ('IsOnAnotherHost', 'https://other-meet.example.com/abc-defg-hij'),
      ('ExtendsTheBaseUrlHost', '$baseUrl.evil.com/abc-defg-hij'),
      ('HasAnExtraSegment', '$baseUrl/other/abc-defg-hij'),
      ('HasNoSlug', '$baseUrl/6f1c2d3e-0000-4000-8000-000000000000'),
    ]) {
      test('execute_whenRoomUrl${name}_throwsAndSendsNothing', () async {
        // Arrange
        givenCreatedRoom(roomUrl);

        // Act
        final start = execute();

        // Assert
        await expectLater(
          start,
          throwsA(isA<VideoCallRoomCreationFailedException>()),
        );
        verifyNothingIsSent();
      });
    }

    test('execute_whenTheRoomIsLeftMeanwhile_sendsNothing', () async {
      // Arrange
      givenCreatedRoom('$baseUrl/abc-defg-hij');
      when(mockVideoCallRepository.isJoined(testRoomId)).thenReturn(false);

      // Act
      final start = execute();

      // Assert
      await expectLater(start, completes);
      verifyNothingIsSent();
    });

    test('execute_whenSendingIsStillPending_completes', () async {
      // Arrange
      givenCreatedRoom('$baseUrl/abc-defg-hij');
      when(
        mockVideoCallRepository.sendCallMessage(
          roomId: anyNamed('roomId'),
          url: anyNamed('url'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) => Completer<void>().future);

      // Act
      final start = execute();

      // Assert
      await expectLater(start, completes);
    });
  });
}

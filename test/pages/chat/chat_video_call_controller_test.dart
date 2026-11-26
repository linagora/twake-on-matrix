import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/exception/video_call/video_call_exception.dart';
import 'package:twake_chat/domain/video_call/usecases/start_video_call_usecase.dart';
import 'package:twake_chat/pages/chat/chat_video_call_controller.dart';
import 'package:twake_chat/pages/chat/chat_video_call_state.dart';

import 'chat_video_call_controller_test.mocks.dart';

@GenerateNiceMocks([MockSpec<StartVideoCallUseCase>()])
void main() {
  const roomId = '!room:example.com';
  late MockStartVideoCallUseCase useCase;
  const userId = '@alice:example.com';
  late ProviderContainer container;

  setUp(() {
    useCase = MockStartVideoCallUseCase();
    container = ProviderContainer.test(retry: (_, _) => null);
  });

  PostExpectation<Future<void>> whenExecute() => when(
    useCase.execute(
      roomId: anyNamed('roomId'),
      baseUrl: anyNamed('baseUrl'),
      startedTitle: anyNamed('startedTitle'),
    ),
  );

  Future<void> start() => container
      .read(chatVideoCallControllerProvider(userId, roomId).notifier)
      .start(useCase, baseUrl: 'https://meet.example.com', startedTitle: 't');

  group('ChatVideoCallController', () {
    test(
      'start_whileAlreadyStartingWithoutListener_callsTheUseCaseOnce',
      () async {
        // Arrange
        final completer = Completer<void>();
        whenExecute().thenAnswer((_) => completer.future);
        final first = start();
        await Future<void>.delayed(Duration.zero);

        // Act
        await start();

        // Assert
        expect(
          container.read(chatVideoCallControllerProvider(userId, roomId)),
          const ChatVideoCallState.starting(),
        );
        completer.complete();
        await first;
        verify(
          useCase.execute(
            roomId: roomId,
            baseUrl: 'https://meet.example.com',
            startedTitle: 't',
          ),
        ).called(1);
      },
    );

    test('start_whenTheUseCaseThrows_rethrowsAndGoesBackToIdle', () async {
      // Arrange
      final sub = container.listen(
        chatVideoCallControllerProvider(userId, roomId),
        (_, _) {},
      );
      addTearDown(sub.close);
      whenExecute().thenThrow(
        VideoCallRoomCreationFailedException(cause: Exception('502')),
      );

      // Act & Assert
      await expectLater(start(), throwsA(isA<VideoCallException>()));
      expect(sub.read(), const ChatVideoCallState.idle());
    });

    test('start_whenDisposedWhilePending_completesWithoutError', () async {
      // Arrange
      final completer = Completer<void>();
      whenExecute().thenAnswer((_) => completer.future);
      final pending = start();
      await Future<void>.delayed(Duration.zero);

      // Act
      container.dispose();
      completer.complete();

      // Assert
      await expectLater(pending, completes);
    });

    test('start_inTheSameRoomFromAnotherAccount_leavesItIdle', () async {
      // Arrange
      final completer = Completer<void>();
      whenExecute().thenAnswer((_) => completer.future);

      // Act
      final pending = start();
      await Future<void>.delayed(Duration.zero);

      // Assert
      expect(
        container.read(
          chatVideoCallControllerProvider('@bob:example.com', roomId),
        ),
        const ChatVideoCallState.idle(),
      );
      completer.complete();
      await pending;
    });
  });
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/exception/video_call/video_call_exception.dart';
import 'package:twake_chat/domain/usecase/video_call/start_video_call_interactor.dart';
import 'package:twake_chat/pages/chat/chat_video_call_view_model.dart';
import 'package:twake_chat/pages/chat/providers/video_call_providers.dart';

import 'chat_video_call_view_model_test.mocks.dart';

@GenerateNiceMocks([MockSpec<StartVideoCallInteractor>(), MockSpec<Client>()])
void main() {
  late MockStartVideoCallInteractor mockInteractor;
  late MockClient mockClient;
  late ProviderContainer container;
  late ChatVideoCallViewModelProvider viewModelProvider;

  const testRoomId = '!room:example.com';
  const baseUrl = 'https://meet.example.com';
  const startedTitle = 'Has started a video call';

  PostExpectation<Future<void>> whenExecute() => when(
    mockInteractor.execute(
      roomId: anyNamed('roomId'),
      baseUrl: anyNamed('baseUrl'),
      startedTitle: anyNamed('startedTitle'),
    ),
  );

  Future<void> start() => container
      .read(viewModelProvider.notifier)
      .start(baseUrl: baseUrl, startedTitle: startedTitle);

  setUp(() {
    mockInteractor = MockStartVideoCallInteractor();
    mockClient = MockClient();
    container = ProviderContainer(
      overrides: [
        startVideoCallInteractorProvider(
          mockClient,
        ).overrideWithValue(mockInteractor),
      ],
    );
    viewModelProvider = chatVideoCallViewModelProvider(
      client: mockClient,
      roomId: testRoomId,
    );
    container.listen(viewModelProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  group('ChatVideoCallViewModel', () {
    test('build_always_startsIdle', () {
      // Act
      final state = container.read(viewModelProvider);

      // Assert
      expect(state, equals(const AsyncData<void>(null)));
    });

    test('start_whileTheCallIsStarting_isLoading', () async {
      // Arrange
      final completer = Completer<void>();
      whenExecute().thenAnswer((_) => completer.future);

      // Act
      final starting = start();

      // Assert
      expect(container.read(viewModelProvider).isLoading, isTrue);
      completer.complete();
      await starting;
    });

    test('start_whenTheCallIsStarted_goesBackToIdle', () async {
      // Act
      await start();

      // Assert
      expect(container.read(viewModelProvider), isA<AsyncData<void>>());
      verify(
        mockInteractor.execute(
          roomId: testRoomId,
          baseUrl: baseUrl,
          startedTitle: startedTitle,
        ),
      ).called(1);
    });

    test('start_whenTheCallFailsToStart_exposesTheError', () async {
      // Arrange
      final failure = VideoCallRoomCreationFailedException(
        cause: Exception('502'),
      );
      whenExecute().thenAnswer((_) => Future.error(failure));

      // Act
      await start();

      // Assert
      expect(container.read(viewModelProvider).error, same(failure));
    });

    test('start_whenCalledAgainAfterAFailure_startsANewCall', () async {
      // Arrange
      whenExecute().thenAnswer((_) => Future.error(Exception('502')));
      await start();
      whenExecute().thenAnswer((_) async {});

      // Act
      await start();

      // Assert
      expect(container.read(viewModelProvider), isA<AsyncData<void>>());
    });

    test('start_whenCalledTwiceConcurrently_startsASingleCall', () async {
      // Arrange
      final completer = Completer<void>();
      whenExecute().thenAnswer((_) => completer.future);

      // Act
      final first = start();
      final second = start();
      completer.complete();
      await Future.wait([first, second]);

      // Assert
      verify(
        mockInteractor.execute(
          roomId: anyNamed('roomId'),
          baseUrl: anyNamed('baseUrl'),
          startedTitle: anyNamed('startedTitle'),
        ),
      ).called(1);
    });

    test('start_whenTheButtonIsRemountedMeanwhile_keepsTheSameCall', () async {
      // Arrange
      final completer = Completer<void>();
      whenExecute().thenAnswer((_) => completer.future);
      final remountContainer = ProviderContainer(
        overrides: [
          startVideoCallInteractorProvider(
            mockClient,
          ).overrideWithValue(mockInteractor),
        ],
      );
      addTearDown(remountContainer.dispose);
      final subscription = remountContainer.listen(
        viewModelProvider,
        (_, _) {},
      );
      final first = remountContainer
          .read(viewModelProvider.notifier)
          .start(baseUrl: baseUrl, startedTitle: startedTitle);

      // Act
      subscription.close();
      await remountContainer.pump();
      remountContainer.listen(viewModelProvider, (_, _) {});
      final isLoadingAfterRemount = remountContainer
          .read(viewModelProvider)
          .isLoading;
      final second = remountContainer
          .read(viewModelProvider.notifier)
          .start(baseUrl: baseUrl, startedTitle: startedTitle);
      completer.complete();
      await Future.wait([first, second]);

      // Assert
      expect(isLoadingAfterRemount, isTrue);
      verify(
        mockInteractor.execute(
          roomId: anyNamed('roomId'),
          baseUrl: anyNamed('baseUrl'),
          startedTitle: anyNamed('startedTitle'),
        ),
      ).called(1);
    });

    test('start_whenDisposedBeforeTheCallIsStarted_completes', () async {
      // Arrange
      final completer = Completer<void>();
      whenExecute().thenAnswer((_) => completer.future);

      // Act
      final starting = start();
      container.dispose();
      completer.complete();

      // Assert
      await expectLater(starting, completes);
    });
  });
}

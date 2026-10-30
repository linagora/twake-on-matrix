import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/repository/forward/forward_repository.provider.dart';
import 'package:twake_chat/domain/repository/forward/forward_repository.dart';
import 'package:twake_chat/pages/forward/forward_controller.dart';
import 'package:twake_chat/pages/forward/forward_state.dart';

import 'forward_controller_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ForwardRepository>()])
void main() {
  const message = {'msgtype': 'm.text', 'body': 'hello'};
  const roomId = '!a:example.com';

  late MockForwardRepository mockRepository;
  late ProviderContainer container;
  late ProviderSubscription<ForwardState> subscription;

  setUp(() {
    mockRepository = MockForwardRepository();
    when(mockRepository.isJoined(any)).thenReturn(true);
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [forwardRepositoryProvider.overrideWithValue(mockRepository)],
    );
    subscription = container.listen(forwardControllerProvider, (_, _) {});
  });

  tearDown(() => subscription.close());

  ForwardController controller() =>
      container.read(forwardControllerProvider.notifier);

  ForwardState state() => container.read(forwardControllerProvider);

  test('build_always_startsIdle', () {
    // Act
    final initial = state();

    // Assert
    expect(initial, const ForwardState.idle());
  });

  test('forward_whenSent_emitsSendingThenDone', () async {
    // Arrange
    final completer = Completer<void>();
    when(
      mockRepository.sendMessage(
        roomId: anyNamed('roomId'),
        content: anyNamed('content'),
      ),
    ).thenAnswer((_) => completer.future);

    // Act
    final future = controller().forward(messages: [message], roomIds: [roomId]);
    final whileSending = state();
    completer.complete();
    await future;

    // Assert
    expect(whileSending, const ForwardState.sending());
    expect(state(), const ForwardState.done(successCount: 1, totalCount: 1));
  });

  test('forward_whenNoMessage_staysIdleAndSendsNothing', () async {
    // Act
    await controller().forward(messages: [], roomIds: [roomId]);

    // Assert
    expect(state(), const ForwardState.idle());
    verifyNever(mockRepository.isJoined(any));
  });

  test('forward_whenUnexpectedError_goesBackToIdle', () async {
    // Arrange
    when(mockRepository.isJoined(any)).thenThrow(StateError('boom'));

    // Act
    final call = controller().forward(messages: [message], roomIds: [roomId]);

    // Assert
    await expectLater(call, throwsStateError);
    expect(state(), const ForwardState.idle());
  });

  test('forward_whileSending_isIgnored', () async {
    // Arrange
    final completer = Completer<void>();
    when(
      mockRepository.sendMessage(
        roomId: anyNamed('roomId'),
        content: anyNamed('content'),
      ),
    ).thenAnswer((_) => completer.future);
    final first = controller().forward(messages: [message], roomIds: [roomId]);

    // Act
    await controller().forward(messages: [message], roomIds: [roomId]);
    completer.complete();
    await first;

    // Assert
    verify(
      mockRepository.sendMessage(roomId: roomId, content: message),
    ).called(1);
  });
}

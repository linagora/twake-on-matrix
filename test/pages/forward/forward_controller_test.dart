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

  late MockForwardRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockForwardRepository();
    when(mockRepository.isJoined(any)).thenReturn(true);
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [forwardRepositoryProvider.overrideWithValue(mockRepository)],
    );
  });

  ForwardController controller() =>
      container.read(forwardControllerProvider.notifier);

  ForwardState state() => container.read(forwardControllerProvider);

  test('build_always_startsWithNoSelection', () {
    expect(state(), const ForwardState.selecting());
  });

  test('toggleRoom_twice_selectsThenUnselectsTheRoom', () {
    controller().toggleRoom('!a:example.com');
    expect(state().selectedRoomIds, ['!a:example.com']);

    controller().toggleRoom('!a:example.com');
    expect(state().selectedRoomIds, isEmpty);
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
    final sub = container.listen(forwardControllerProvider, (_, _) {});
    controller().toggleRoom('!a:example.com');

    // Act
    final future = controller().forward([message]);

    // Assert
    expect(
      state(),
      const ForwardState.sending(selectedRoomIds: ['!a:example.com']),
    );
    completer.complete();
    await future;
    expect(
      state(),
      const ForwardState.done(
        selectedRoomIds: ['!a:example.com'],
        successCount: 1,
        totalCount: 1,
      ),
    );
    sub.close();
  });

  test('forward_whenNoMessage_goesBackToSelecting', () async {
    // Arrange
    final sub = container.listen(forwardControllerProvider, (_, _) {});
    controller().toggleRoom('!a:example.com');

    // Act
    await controller().forward([]);

    // Assert
    expect(
      state(),
      const ForwardState.selecting(selectedRoomIds: ['!a:example.com']),
    );
    sub.close();
  });

  test('toggleRoom_whileSending_isIgnored', () async {
    // Arrange
    final completer = Completer<void>();
    when(
      mockRepository.sendMessage(
        roomId: anyNamed('roomId'),
        content: anyNamed('content'),
      ),
    ).thenAnswer((_) => completer.future);
    final sub = container.listen(forwardControllerProvider, (_, _) {});
    controller().toggleRoom('!a:example.com');
    final future = controller().forward([message]);

    // Act
    controller().toggleRoom('!b:example.com');

    // Assert
    expect(state().selectedRoomIds, ['!a:example.com']);
    completer.complete();
    await future;
    sub.close();
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/forward/exceptions/forward_exception.dart';
import 'package:twake_chat/domain/forward/usecases/forward_messages_usecase.dart';
import 'package:twake_chat/domain/repository/forward/forward_repository.dart';

import 'forward_messages_usecase_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ForwardRepository>()])
void main() {
  const firstMessage = {'msgtype': 'm.text', 'body': 'first'};
  const secondMessage = {'msgtype': 'm.text', 'body': 'second'};

  late MockForwardRepository mockRepository;
  late ForwardMessagesUseCase useCase;

  setUp(() {
    mockRepository = MockForwardRepository();
    useCase = ForwardMessagesUseCase(mockRepository);
    when(mockRepository.isJoined(any)).thenReturn(true);
  });

  test('execute_whenNoMessage_throwsForwardEmptyContentException', () async {
    await expectLater(
      useCase.execute(messages: [], roomIds: ['!a:example.com']),
      throwsA(isA<ForwardEmptyContentException>()),
    );
    verifyNever(
      mockRepository.sendMessage(
        roomId: anyNamed('roomId'),
        content: anyNamed('content'),
      ),
    );
  });

  test('execute_always_sendsEveryMessageToEveryRoomInOrder', () async {
    // Act
    final result = await useCase.execute(
      messages: [firstMessage, secondMessage],
      roomIds: ['!a:example.com', '!b:example.com'],
    );

    // Assert
    verifyInOrder([
      mockRepository.sendMessage(
        roomId: '!a:example.com',
        content: firstMessage,
      ),
      mockRepository.sendMessage(
        roomId: '!a:example.com',
        content: secondMessage,
      ),
      mockRepository.sendMessage(
        roomId: '!b:example.com',
        content: firstMessage,
      ),
      mockRepository.sendMessage(
        roomId: '!b:example.com',
        content: secondMessage,
      ),
    ]);
    expect(result.successCount, 2);
    expect(result.totalCount, 2);
  });

  test('execute_whenRoomIsNotJoined_skipsItAndCountsItAsFailed', () async {
    // Arrange
    when(mockRepository.isJoined('!left:example.com')).thenReturn(false);

    // Act
    final result = await useCase.execute(
      messages: [firstMessage],
      roomIds: ['!left:example.com', '!b:example.com'],
    );

    // Assert
    verifyNever(
      mockRepository.sendMessage(
        roomId: '!left:example.com',
        content: anyNamed('content'),
      ),
    );
    expect(result.successCount, 1);
    expect(result.totalCount, 2);
  });

  test('execute_whenOneRoomFails_stillSendsToTheOthers', () async {
    // Arrange
    when(
      mockRepository.sendMessage(
        roomId: '!a:example.com',
        content: anyNamed('content'),
      ),
    ).thenThrow(Exception('network'));

    // Act
    final result = await useCase.execute(
      messages: [firstMessage],
      roomIds: ['!a:example.com', '!b:example.com'],
    );

    // Assert
    verify(
      mockRepository.sendMessage(
        roomId: '!b:example.com',
        content: firstMessage,
      ),
    ).called(1);
    expect(result.successCount, 1);
    expect(result.totalCount, 2);
  });
}

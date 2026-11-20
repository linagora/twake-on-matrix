import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/direct_chat/repositories/direct_chat_repository.dart';
import 'package:twake_chat/domain/direct_chat/usecases/find_direct_chat_usecase.dart';

class _FakeDirectChatRepository extends Fake implements DirectChatRepository {
  @override
  String? findDirectChat({required String contactMxId}) =>
      contactMxId == '@alice:server' ? '!dm:server' : null;
}

void main() {
  final useCase = FindDirectChatUseCase(_FakeDirectChatRepository());

  test('execute_withExistingDirectChat_returnsItsRoomId', () async {
    // Act
    final roomId = await useCase.execute(contactMxId: '@alice:server');

    // Assert
    expect(roomId, '!dm:server');
  });

  test('execute_withoutDirectChat_returnsNull', () async {
    // Act
    final roomId = await useCase.execute(contactMxId: '@bob:server');

    // Assert
    expect(roomId, isNull);
  });
}

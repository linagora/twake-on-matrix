import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/exception/public_rooms/public_rooms_exception.dart';
import 'package:twake_chat/domain/public_rooms/usecases/knock_public_room_usecase.dart';

import '../fake_public_rooms_repository.dart';

void main() {
  test('execute_whenTheRoomIsOnApproval_sendsTheRequest', () async {
    // Arrange
    final repository = FakePublicRoomsRepository();

    // Act
    await KnockPublicRoomUseCase(repository).execute('!a:hs');

    // Assert
    expect(repository.knockedIds, ['!a:hs']);
  });

  test('execute_whenTheKnockFails_throwsKnockFailed', () async {
    // Arrange
    final repository = FakePublicRoomsRepository(
      knockError: PublicRoomKnockFailedException(cause: Exception('forbidden')),
    );

    // Act
    final result = KnockPublicRoomUseCase(repository).execute('!a:hs');

    // Assert
    await expectLater(result, throwsA(isA<PublicRoomKnockFailedException>()));
  });
}

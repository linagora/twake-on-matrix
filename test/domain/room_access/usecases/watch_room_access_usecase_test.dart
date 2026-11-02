import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/room_access/entities/room_access.dart';
import 'package:twake_chat/domain/room_access/repositories/room_access_repository.dart';
import 'package:twake_chat/domain/room_access/usecases/watch_room_access_usecase.dart';

import 'watch_room_access_usecase_test.mocks.dart';

@GenerateNiceMocks([MockSpec<RoomAccessRepository>()])
void main() {
  test('execute_always_emitsTheRepositoryAccess', () async {
    // Arrange
    const access = RoomAccess(
      joinRule: JoinRuleChoice.knock,
      isListed: true,
      isEncrypted: false,
      canChange: true,
    );
    final repository = MockRoomAccessRepository();
    when(
      repository.watchRoomAccess('!room:example.com'),
    ).thenAnswer((_) => Stream.value(access));

    // Act
    final result = WatchRoomAccessUseCase(
      repository,
    ).execute('!room:example.com');

    // Assert
    await expectLater(result, emits(access));
  });
}

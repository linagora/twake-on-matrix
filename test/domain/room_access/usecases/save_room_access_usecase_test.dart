import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/exception/room_access/room_access_exception.dart';
import 'package:twake_chat/domain/room_access/entities/room_access.dart';
import 'package:twake_chat/domain/room_access/usecases/get_room_access_usecase.dart';
import 'package:twake_chat/domain/room_access/usecases/save_room_access_usecase.dart';

import '../fake_room_access_repository.dart';

void main() {
  const roomId = '!room:example.com';
  const encrypted = RoomAccess(
    joinRule: JoinRuleChoice.invite,
    isListed: false,
    isEncrypted: true,
    canChange: true,
  );

  late FakeRoomAccessRepository repository;
  late SaveRoomAccessUseCase useCase;

  setUp(() {
    repository = FakeRoomAccessRepository();
    useCase = SaveRoomAccessUseCase(repository);
  });

  test('execute_withRuleAndListing_setsTheRuleBeforeTheListing', () async {
    // Act
    await useCase.execute(
      roomId,
      joinRule: JoinRuleChoice.public,
      isListed: true,
    );

    // Assert
    expect(repository.calls, ['joinRule:public', 'listed:true']);
  });

  test('execute_whenTheRuleIsRefused_neverListsTheRoom', () async {
    // Arrange
    repository.setJoinRuleError = const RoomAccessForbiddenException(
      cause: 'x',
    );

    // Act
    final result = useCase.execute(
      roomId,
      joinRule: JoinRuleChoice.public,
      isListed: true,
    );

    // Assert
    await expectLater(result, throwsA(isA<RoomAccessForbiddenException>()));
    expect(repository.calls, ['joinRule:public']);
  });

  test('execute_withNothingChanged_sendsNothing', () async {
    // Act
    await useCase.execute(roomId);

    // Assert
    expect(repository.calls, isEmpty);
  });

  test('execute_publicOnAnEncryptedRoom_throwsAndSendsNothing', () async {
    // Arrange
    repository.access = encrypted;

    // Act
    final result = useCase.execute(roomId, joinRule: JoinRuleChoice.public);

    // Assert
    await expectLater(result, throwsA(isA<RoomAccessEncryptedException>()));
    expect(repository.calls, isEmpty);
  });

  test('execute_listingAnEncryptedRoom_throwsAndSendsNothing', () async {
    // Arrange
    repository.access = encrypted;

    // Act
    final result = useCase.execute(roomId, isListed: true);

    // Assert
    await expectLater(result, throwsA(isA<RoomAccessEncryptedException>()));
    expect(repository.calls, isEmpty);
  });

  test('execute_unlistingAnEncryptedRoom_isAllowed', () async {
    // Arrange
    repository.access = encrypted;

    // Act
    await useCase.execute(
      roomId,
      joinRule: JoinRuleChoice.invite,
      isListed: false,
    );

    // Assert
    expect(repository.calls, ['joinRule:invite', 'listed:false']);
  });

  test('getRoomAccess_execute_returnsTheRepositoryAccess', () async {
    // Act
    final access = await GetRoomAccessUseCase(repository).execute(roomId);

    // Assert
    expect(access, repository.access);
  });
}

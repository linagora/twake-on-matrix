import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/room_access/entities/room_access.dart';
import 'package:twake_chat/domain/room_access/exceptions/room_access_exception.dart';
import 'package:twake_chat/domain/room_access/repositories/room_access_repository.dart';
import 'package:twake_chat/domain/room_access/usecases/save_room_access_usecase.dart';

import 'save_room_access_usecase_test.mocks.dart';

@GenerateNiceMocks([MockSpec<RoomAccessRepository>()])
void main() {
  const roomId = '!room:example.com';

  late MockRoomAccessRepository repository;
  late SaveRoomAccessUseCase useCase;

  setUp(() {
    repository = MockRoomAccessRepository();
    when(repository.isEncrypted(roomId)).thenReturn(false);
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
    verifyInOrder([
      repository.setJoinRule(roomId, JoinRuleChoice.public),
      repository.setListed(roomId, isListed: true),
    ]);
  });

  test('execute_whenTheRuleIsRefused_neverListsTheRoom', () async {
    // Arrange
    when(
      repository.setJoinRule(roomId, JoinRuleChoice.public),
    ).thenThrow(const RoomAccessForbiddenException(cause: 'x'));

    // Act
    final result = useCase.execute(
      roomId,
      joinRule: JoinRuleChoice.public,
      isListed: true,
    );

    // Assert
    await expectLater(result, throwsA(isA<RoomAccessForbiddenException>()));
    verifyNever(repository.setListed(any, isListed: anyNamed('isListed')));
  });

  test('execute_withNothingChanged_sendsNothing', () async {
    // Act
    await useCase.execute(roomId);

    // Assert
    verifyNever(repository.setJoinRule(any, any));
    verifyNever(repository.setListed(any, isListed: anyNamed('isListed')));
  });

  test('execute_publicOnAnEncryptedRoom_throwsAndSendsNothing', () async {
    // Arrange
    when(repository.isEncrypted(roomId)).thenReturn(true);

    // Act
    final result = useCase.execute(roomId, joinRule: JoinRuleChoice.public);

    // Assert
    await expectLater(result, throwsA(isA<RoomAccessEncryptedException>()));
    verifyNever(repository.setJoinRule(any, any));
  });

  test('execute_listingAnEncryptedRoom_throwsAndSendsNothing', () async {
    // Arrange
    when(repository.isEncrypted(roomId)).thenReturn(true);

    // Act
    final result = useCase.execute(roomId, isListed: true);

    // Assert
    await expectLater(result, throwsA(isA<RoomAccessEncryptedException>()));
    verifyNever(repository.setListed(any, isListed: anyNamed('isListed')));
  });

  test('execute_unlistingAnEncryptedRoom_isAllowed', () async {
    // Arrange
    when(repository.isEncrypted(roomId)).thenReturn(true);

    // Act
    await useCase.execute(
      roomId,
      joinRule: JoinRuleChoice.invite,
      isListed: false,
    );

    // Assert
    verifyInOrder([
      repository.setJoinRule(roomId, JoinRuleChoice.invite),
      repository.setListed(roomId, isListed: false),
    ]);
  });

  group('with the public page on', () {
    setUp(() => when(repository.hasPublicPage(roomId)).thenReturn(true));

    test('execute_privateRule_throwsAndSendsNothing', () async {
      // Act
      final result = useCase.execute(roomId, joinRule: JoinRuleChoice.knock);

      // Assert
      await expectLater(result, throwsA(isA<RoomAccessPublicPageException>()));
      verifyNever(repository.setJoinRule(any, any));
    });

    test('execute_unlisting_throwsAndSendsNothing', () async {
      // Act
      final result = useCase.execute(roomId, isListed: false);

      // Assert
      await expectLater(result, throwsA(isA<RoomAccessPublicPageException>()));
      verifyNever(repository.setListed(any, isListed: anyNamed('isListed')));
    });

    test('execute_publicAndListed_isAllowed', () async {
      // Act
      await useCase.execute(
        roomId,
        joinRule: JoinRuleChoice.public,
        isListed: true,
      );

      // Assert
      verify(repository.setJoinRule(roomId, JoinRuleChoice.public)).called(1);
      verify(repository.setListed(roomId, isListed: true)).called(1);
    });
  });
}

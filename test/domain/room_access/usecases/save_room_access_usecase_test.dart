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

  void guard({bool isEncrypted = false, bool hasPublicPage = false}) =>
      when(repository.guardsOf(roomId)).thenReturn(
        RoomAccessGuards(
          isEncrypted: isEncrypted,
          hasPublicPage: hasPublicPage,
        ),
      );

  setUp(() {
    repository = MockRoomAccessRepository();
    guard();
    useCase = SaveRoomAccessUseCase(repository);
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

  for (final (name, encrypted, page, joinRule, isListed, refusal) in [
    (
      'publicOnAnEncryptedRoom',
      true,
      false,
      JoinRuleChoice.public,
      null,
      isA<RoomAccessEncryptedException>(),
    ),
    (
      'listingAnEncryptedRoom',
      true,
      false,
      null,
      true,
      isA<RoomAccessEncryptedException>(),
    ),
    (
      'privateRuleWithAPublicPage',
      false,
      true,
      JoinRuleChoice.knock,
      null,
      isA<RoomAccessPublicPageException>(),
    ),
    (
      'unlistingWithAPublicPage',
      false,
      true,
      null,
      false,
      isA<RoomAccessPublicPageException>(),
    ),
  ]) {
    test('execute_${name}_throwsAndSendsNothing', () async {
      // Arrange
      guard(isEncrypted: encrypted, hasPublicPage: page);

      // Act
      final result = useCase.execute(
        roomId,
        joinRule: joinRule,
        isListed: isListed,
      );

      // Assert
      await expectLater(result, throwsA(refusal));
      verifyNever(repository.setJoinRule(any, any));
      verifyNever(repository.setListed(any, isListed: anyNamed('isListed')));
    });
  }

  for (final (name, encrypted, page, joinRule, isListed) in [
    ('openRoom', false, false, JoinRuleChoice.public, true),
    ('closingAnEncryptedRoom', true, false, JoinRuleChoice.invite, false),
    ('keepingAPublicPageOpen', false, true, JoinRuleChoice.public, true),
  ]) {
    test('execute_${name}_setsTheRuleBeforeTheListing', () async {
      // Arrange
      guard(isEncrypted: encrypted, hasPublicPage: page);

      // Act
      await useCase.execute(roomId, joinRule: joinRule, isListed: isListed);

      // Assert
      verifyInOrder([
        repository.setJoinRule(roomId, joinRule),
        repository.setListed(roomId, isListed: isListed),
      ]);
    });
  }
}

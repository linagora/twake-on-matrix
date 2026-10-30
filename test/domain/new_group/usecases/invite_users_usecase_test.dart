import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/exception/room/invite_user_exception.dart';
import 'package:twake_chat/domain/new_group/usecases/invite_users_usecase.dart';
import 'package:twake_chat/domain/repository/new_group/new_group_repository.dart';

import 'invite_users_usecase_test.mocks.dart';

@GenerateNiceMocks([MockSpec<NewGroupRepository>()])
void main() {
  const roomId = '!room:example.com';

  late MockNewGroupRepository mockRepository;
  late InviteUsersUseCase useCase;

  setUp(() {
    mockRepository = MockNewGroupRepository();
    useCase = InviteUsersUseCase(mockRepository);
  });

  test('execute_whenAllInvited_completes', () async {
    // Act
    await useCase.execute(roomId: roomId, userIds: ['@a:x', '@b:x']);

    // Assert
    verify(mockRepository.inviteUser(roomId: roomId, userId: '@a:x')).called(1);
    verify(mockRepository.inviteUser(roomId: roomId, userId: '@b:x')).called(1);
  });

  test('execute_whenSomeFail_invitesTheOthersThenThrowsTheFailures', () async {
    // Arrange
    const failure = GenericInviteException(userId: '@a:x', message: 'nope');
    when(
      mockRepository.inviteUser(roomId: roomId, userId: '@a:x'),
    ).thenThrow(failure);

    // Act & Assert
    await expectLater(
      useCase.execute(roomId: roomId, userIds: ['@a:x', '@b:x']),
      throwsA(
        isA<InviteUserPartialFailureException>().having(
          (e) => e.failedUsers,
          'failedUsers',
          {'@a:x': failure},
        ),
      ),
    );
    verify(mockRepository.inviteUser(roomId: roomId, userId: '@b:x')).called(1);
  });
}

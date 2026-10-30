import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/exception/room/can_not_create_new_group_chat_exception.dart';
import 'package:twake_chat/domain/model/room/create_new_group_chat_request.dart';
import 'package:twake_chat/domain/new_group/usecases/create_group_usecase.dart';
import 'package:twake_chat/domain/repository/new_group/new_group_repository.dart';

import 'create_group_usecase_test.mocks.dart';

@GenerateNiceMocks([MockSpec<NewGroupRepository>()])
void main() {
  const request = CreateNewGroupChatRequest(groupName: 'Team');

  late MockNewGroupRepository mockRepository;
  late CreateGroupUseCase useCase;

  setUp(() {
    mockRepository = MockNewGroupRepository();
    useCase = CreateGroupUseCase(mockRepository);
  });

  test('execute_whenCreated_returnsTheRoomId', () async {
    // Arrange
    when(
      mockRepository.createGroup(request),
    ).thenAnswer((_) async => '!room:example.com');

    // Act
    final roomId = await useCase.execute(request);

    // Assert
    expect(roomId, '!room:example.com');
  });

  test('execute_whenRoomIdIsEmpty_throwsCannotCreate', () async {
    // Arrange
    when(mockRepository.createGroup(request)).thenAnswer((_) async => '');

    // Act & Assert
    await expectLater(
      useCase.execute(request),
      throwsA(isA<CannotCreateNewGroupChatException>()),
    );
  });

  for (final (name, message, matcher) in [
    (
      'FederationDenied',
      'M_FORBIDDEN: Federation denied with matrix.org.',
      isA<FederationDeniedWithMatrixOrgException>(),
    ),
    (
      'TooManyInvites',
      'M_UNKNOWN: Cannot invite so many users at once',
      isA<CannotCreateNewGroupChatWithLimitedPermissionsException>(),
    ),
  ]) {
    test('execute_when${name}_throwsTheTypedException', () async {
      // Arrange
      when(
        mockRepository.createGroup(request),
      ).thenAnswer((_) => Future.error(Exception(message)));

      // Act & Assert
      await expectLater(useCase.execute(request), throwsA(matcher));
    });
  }

  test('execute_whenOtherError_rethrowsIt', () async {
    // Arrange
    final error = Exception('boom');
    when(
      mockRepository.createGroup(request),
    ).thenAnswer((_) => Future.error(error));

    // Act & Assert
    await expectLater(useCase.execute(request), throwsA(same(error)));
  });
}

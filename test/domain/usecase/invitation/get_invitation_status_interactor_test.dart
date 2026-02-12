import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluffychat/data/model/invitation/invitation_status_response.dart';
import 'package:fluffychat/domain/app_state/invitation/get_invitation_status_state.dart';
import 'package:fluffychat/domain/repository/invitation/invitation_repository.dart';
import 'package:fluffychat/domain/usecase/invitation/get_invitation_status_interactor.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'get_invitation_status_interactor_test.mocks.dart';

@GenerateMocks([InvitationRepository])
void main() {
  late GetInvitationStatusInteractor interactor;
  late MockInvitationRepository mockRepository;

  setUp(() {
    mockRepository = MockInvitationRepository();
    GetIt.instance.registerSingleton<InvitationRepository>(mockRepository);
    interactor = GetInvitationStatusInteractor();
  });

  tearDown(() {
    GetIt.instance.reset();
    reset(mockRepository);
  });

  const testUserId = 'user123';
  const testContactId = 'contact123';
  const testInvitationId = 'inv123';

  test('execute returns empty state when invitation status is null', () async {
    final response = InvitationStatusResponse(invitation: null);

    when(
      mockRepository.getInvitationStatus(invitationId: testInvitationId),
    ).thenAnswer((_) async => response);

    final result = interactor.execute(
      userId: testUserId,
      contactId: testContactId,
      invitationId: testInvitationId,
    );

    await expectLater(
      result,
      emitsInOrder([
        const Right(GetInvitationStatusLoadingState()),
        const Left(
          GetInvitationStatusEmptyState(
            contactId: testContactId,
            userId: testUserId,
            invitationId: testInvitationId,
          ),
        ),
        Right(
          GetInvitationStatusSuccessState(invitationStatusResponse: response),
        ),
      ]),
    );
  });

  test('execute returns success state when invitation is not null', () async {
    final response = InvitationStatusResponse(
      invitation: Invitation(
        id: testInvitationId,
        sender: 'sender@example.com',
        recepient: 'recipient@example.com',
        medium: 'email',
        expiration: DateTime.now().millisecondsSinceEpoch,
        accessed: false,
        roomId: 'room123',
        matrixId: 'matrix123',
      ),
    );

    when(
      mockRepository.getInvitationStatus(invitationId: testInvitationId),
    ).thenAnswer((_) async => response);

    final result = interactor.execute(
      userId: testUserId,
      contactId: testContactId,
      invitationId: testInvitationId,
    );

    await expectLater(
      result,
      emitsInOrder([
        const Right(GetInvitationStatusLoadingState()),
        Right(
          GetInvitationStatusSuccessState(invitationStatusResponse: response),
        ),
      ]),
    );
  });

  test('execute returns failure state on error', () async {
    when(
      mockRepository.getInvitationStatus(invitationId: testInvitationId),
    ).thenThrow(Exception('Test error'));

    final result = interactor.execute(
      userId: testUserId,
      contactId: testContactId,
      invitationId: testInvitationId,
    );

    await expectLater(
      result,
      emitsInOrder([
        predicate(
          (dynamic value) =>
              value is Right && value.value is GetInvitationStatusLoadingState,
        ),
        predicate(
          (dynamic value) =>
              value is Left && value.value is GetInvitationStatusFailureState,
        ),
      ]),
    );
  });

  test('execute returns failure state with message on DioException', () async {
    when(
      mockRepository.getInvitationStatus(invitationId: testInvitationId),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(),
        response: Response(
          requestOptions: RequestOptions(),
          data: {'message': 'Test error message'},
        ),
      ),
    );

    final result = interactor.execute(
      userId: testUserId,
      contactId: testContactId,
      invitationId: testInvitationId,
    );

    await expectLater(
      result,
      emitsInOrder([
        predicate(
          (dynamic value) =>
              value is Right && value.value is GetInvitationStatusLoadingState,
        ),
        predicate(
          (dynamic value) =>
              value is Left && value.value is GetInvitationStatusFailureState,
        ),
      ]),
    );
  });
}

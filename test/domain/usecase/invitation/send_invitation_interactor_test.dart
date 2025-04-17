import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:fluffychat/data/model/invitation/invitation_request.dart';
import 'package:fluffychat/data/model/invitation/send_invitation_response.dart';
import 'package:fluffychat/domain/app_state/invitation/send_invitation_state.dart';
import 'package:fluffychat/domain/model/invitation/invitation_medium_enum.dart';
import 'package:fluffychat/domain/repository/invitation/invitation_repository.dart';
import 'package:fluffychat/domain/usecase/invitation/send_invitation_interactor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'send_invitation_interactor_test.mocks.dart';

@GenerateMocks([
  InvitationRepository,
])
void main() {
  late SendInvitationInteractor interactor;
  late MockInvitationRepository mockRepository;

  setUp(() {
    mockRepository = MockInvitationRepository();
    GetIt.instance.registerSingleton<InvitationRepository>(mockRepository);
    interactor = SendInvitationInteractor();
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  const testContact = 'test@example.com';
  const testContactId = 'contact123';
  const testMedium = InvitationMediumEnum.email;

  test('execute returns success state when invitation is sent successfully',
      () async {
    final response = SendInvitationResponse(
      id: 'inv123',
      message: 'Invitation sent successfully',
    );

    when(
      mockRepository.sendInvitation(
        request: InvitationRequest(
          contact: testContact,
          medium: testMedium.value,
        ),
      ),
    ).thenAnswer((_) async => response);

    final result = interactor.execute(
      contact: testContact,
      contactId: testContactId,
      medium: testMedium,
    );

    await expectLater(
      result,
      emitsInOrder([
        const Right(SendInvitationLoadingState()),
        Right(
          SendInvitationSuccessState(
            sendInvitationResponse: response,
            contactId: testContactId,
          ),
        ),
      ]),
    );
  });

  test('execute returns failure state when invitation already sent', () async {
    when(
      mockRepository.sendInvitation(
        request: InvitationRequest(
          contact: testContact,
          medium: testMedium.value,
        ),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(),
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 400,
          data: {'message': 'You already sent an invitation to this contact'},
        ),
      ),
    );

    final result = interactor.execute(
      contact: testContact,
      contactId: testContactId,
      medium: testMedium,
    );

    await expectLater(
      result,
      emitsInOrder([
        const Right(SendInvitationLoadingState()),
        const Left(InvitationAlreadySentState()),
      ]),
    );
  });

  test('execute returns failure state on general error', () async {
    when(
      mockRepository.sendInvitation(
        request: InvitationRequest(
          contact: testContact,
          medium: testMedium.value,
        ),
      ),
    ).thenThrow(Exception('Test error'));

    final result = interactor.execute(
      contact: testContact,
      contactId: testContactId,
      medium: testMedium,
    );

    await expectLater(
      result,
      emitsInOrder([
        const Right(SendInvitationLoadingState()),
        predicate(
          (dynamic value) =>
              value is Left && value.value is SendInvitationFailureState,
        ),
      ]),
    );
  });
}

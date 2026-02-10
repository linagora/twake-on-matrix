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

@GenerateMocks([InvitationRepository])
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

  test(
    'execute returns success state when invitation is sent successfully',
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
    },
  );

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

  test(
    'execute calls repository with normalized phone number when medium is phone',
    () async {
      const unnormalizedPhoneNumber = '+1 (123) 456-7890';
      const normalizedPhoneNumber = '+11234567890';
      const phoneContactId = 'phoneContact456';
      const phoneMedium = InvitationMediumEnum.phone;

      final response = SendInvitationResponse(
        id: 'inv456',
        message: 'Invitation sent successfully via phone',
      );

      when(
        mockRepository.sendInvitation(
          request: InvitationRequest(
            contact: normalizedPhoneNumber, // Expect normalized number
            medium: phoneMedium.value,
          ),
        ),
      ).thenAnswer((_) async => response);

      final result = interactor.execute(
        contact: unnormalizedPhoneNumber, // Use unnormalized number here
        contactId: phoneContactId,
        medium: phoneMedium,
      );

      // Wait for the stream to complete
      await result.last;

      // Verify that sendInvitation was called with the normalized number
      verify(
        mockRepository.sendInvitation(
          request: InvitationRequest(
            contact: normalizedPhoneNumber,
            medium: phoneMedium.value,
          ),
        ),
      ).called(1);
    },
  );

  test(
    'execute calls repository with original contact when medium is not phone',
    () async {
      const emailContact = 'user@domain.com';
      const emailContactId = 'emailContact789';
      const emailMedium = InvitationMediumEnum.email; // Not phone

      final response = SendInvitationResponse(
        id: 'inv789',
        message: 'Invitation sent successfully via email',
      );

      when(
        mockRepository.sendInvitation(
          request: InvitationRequest(
            contact: emailContact, // Expect original email
            medium: emailMedium.value,
          ),
        ),
      ).thenAnswer((_) async => response);

      final result = interactor.execute(
        contact: emailContact,
        contactId: emailContactId,
        medium: emailMedium,
      );

      await result.last; // Wait for completion

      verify(
        mockRepository.sendInvitation(
          request: InvitationRequest(
            contact: emailContact,
            medium: emailMedium.value,
          ),
        ),
      ).called(1);
    },
  );

  test(
    'execute calls repository with already normalized phone number when medium is phone',
    () async {
      const alreadyNormalized = '+19876543210';
      const phoneContactId = 'phoneContactAlreadyNorm';
      const phoneMedium = InvitationMediumEnum.phone;

      final response = SendInvitationResponse(
        id: 'invAlreadyNorm',
        message: 'Sent',
      );

      when(
        mockRepository.sendInvitation(
          request: InvitationRequest(
            contact: alreadyNormalized, // Expect the same normalized number
            medium: phoneMedium.value,
          ),
        ),
      ).thenAnswer((_) async => response);

      final result = interactor.execute(
        contact: alreadyNormalized,
        contactId: phoneContactId,
        medium: phoneMedium,
      );

      await result.last; // Wait for completion

      verify(
        mockRepository.sendInvitation(
          request: InvitationRequest(
            contact: alreadyNormalized,
            medium: phoneMedium.value,
          ),
        ),
      ).called(1);
    },
  );

  test(
    'execute calls repository with empty string when phone number is empty',
    () async {
      const emptyContact = '';
      const phoneContactId = 'phoneContactEmpty';
      const phoneMedium = InvitationMediumEnum.phone;

      final response = SendInvitationResponse(id: 'invEmpty', message: 'Sent');

      when(
        mockRepository.sendInvitation(
          request: InvitationRequest(
            contact: emptyContact, // Expect empty string
            medium: phoneMedium.value,
          ),
        ),
      ).thenAnswer((_) async => response);

      final result = interactor.execute(
        contact: emptyContact,
        contactId: phoneContactId,
        medium: phoneMedium,
      );

      await result.last; // Wait for completion

      verify(
        mockRepository.sendInvitation(
          request: InvitationRequest(
            contact: emptyContact,
            medium: phoneMedium.value,
          ),
        ),
      ).called(1);
    },
  );

  test(
    'execute calls repository with empty string for non-normalizable phone number',
    () async {
      const nonNormalizable = 'abc-() .';
      const expectedContact = ''; // Normalization should result in empty
      const phoneContactId = 'phoneContactNonNorm';
      const phoneMedium = InvitationMediumEnum.phone;

      final response = SendInvitationResponse(
        id: 'invNonNorm',
        message: 'Sent',
      );

      when(
        mockRepository.sendInvitation(
          request: InvitationRequest(
            contact: expectedContact, // Expect empty string
            medium: phoneMedium.value,
          ),
        ),
      ).thenAnswer((_) async => response);

      final result = interactor.execute(
        contact: nonNormalizable,
        contactId: phoneContactId,
        medium: phoneMedium,
      );

      await result.last; // Wait for completion

      verify(
        mockRepository.sendInvitation(
          request: InvitationRequest(
            contact: expectedContact,
            medium: phoneMedium.value,
          ),
        ),
      ).called(1);
    },
  );

  test(
    'execute calls repository with plus sign only for phone number with only plus',
    () async {
      const plusOnly = '+';
      const expectedContact = '+'; // Normalization should result in '+'
      const phoneContactId = 'phoneContactPlusOnly';
      const phoneMedium = InvitationMediumEnum.phone;

      final response = SendInvitationResponse(
        id: 'invPlusOnly',
        message: 'Sent',
      );

      when(
        mockRepository.sendInvitation(
          request: InvitationRequest(
            contact: expectedContact, // Expect '+'
            medium: phoneMedium.value,
          ),
        ),
      ).thenAnswer((_) async => response);

      final result = interactor.execute(
        contact: plusOnly,
        contactId: phoneContactId,
        medium: phoneMedium,
      );

      await result.last; // Wait for completion

      verify(
        mockRepository.sendInvitation(
          request: InvitationRequest(
            contact: expectedContact,
            medium: phoneMedium.value,
          ),
        ),
      ).called(1);
    },
  );

  // New test cases added
  test(
    'execute returns failure state when invalid phone number is provided',
    () async {
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
            data: {'message': 'Invalid phone number'},
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
          const Left(InvalidPhoneNumberFailureState()),
        ]),
      );
    },
  );

  test(
    'execute returns failure state when invalid email is provided',
    () async {
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
            data: {'message': 'Invalid email address'},
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
          const Left(InvalidEmailFailureState()),
        ]),
      );
    },
  );

  test(
    'execute returns failure state when response is not a map or missing message',
    () async {
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
            data: 'Invalid response format', // Not a map
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
          predicate(
            (dynamic value) =>
                value is Left && value.value is SendInvitationFailureState,
          ),
        ]),
      );
    },
  );

  test(
    'execute returns failure state when response is a map but missing message',
    () async {
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
            data: {'error': 'Invalid response format'},
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
          predicate(
            (dynamic value) =>
                value is Left && value.value is SendInvitationFailureState,
          ),
        ]),
      );
    },
  );
}

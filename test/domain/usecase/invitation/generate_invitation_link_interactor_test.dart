import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:fluffychat/data/model/invitation/generate_invitation_link_response.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluffychat/data/model/invitation/invitation_request.dart';
import 'package:fluffychat/domain/app_state/invitation/generate_invitation_link_state.dart';
import 'package:fluffychat/domain/model/invitation/invitation_medium_enum.dart';
import 'package:fluffychat/domain/repository/invitation/invitation_repository.dart';
import 'package:fluffychat/domain/usecase/invitation/generate_invitation_link_interactor.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'generate_invitation_link_interactor_test.mocks.dart';

@GenerateMocks([
  InvitationRepository,
])
void main() {
  late GenerateInvitationLinkInteractor interactor;
  late MockInvitationRepository mockRepository;

  setUp(() {
    mockRepository = MockInvitationRepository();
    GetIt.instance.registerSingleton<InvitationRepository>(mockRepository);
    interactor = GenerateInvitationLinkInteractor();
  });

  tearDown(() {
    GetIt.instance.reset();
    reset(mockRepository);
  });

  const testContact = 'test@example.com';
  const testMedium = InvitationMediumEnum.email;

  test('execute returns success state when link is generated successfully',
      () async {
    final response = GenerateInvitationLinkResponse(
      id: 'inv123',
      link: 'https://test.link',
    );

    when(
      mockRepository.generateInvitationLink(
        request: InvitationRequest(
          contact: testContact,
          medium: testMedium.value,
        ),
      ),
    ).thenAnswer((_) async => response);

    final result = interactor.execute(
      contact: testContact,
      medium: testMedium,
    );

    await expectLater(
      result,
      emitsInOrder([
        const Right(GenerateInvitationLinkLoadingState()),
        const Right(
          GenerateInvitationLinkSuccessState(
            link: 'https://test.link',
            id: 'inv123',
          ),
        ),
      ]),
    );
  });

  test(
      'execute returns success state when link is generated successfully with null contact',
      () async {
    final response = GenerateInvitationLinkResponse(
      id: 'inv123',
      link: 'https://test.link',
    );

    when(
      mockRepository.generateInvitationLink(
        request: InvitationRequest(contact: null, medium: null),
      ),
    ).thenAnswer((_) async => response);

    final result = interactor.execute(
      contact: null,
      medium: null,
    );

    await expectLater(
      result,
      emitsInOrder([
        const Right(GenerateInvitationLinkLoadingState()),
        const Right(
          GenerateInvitationLinkSuccessState(
            link: 'https://test.link',
            id: 'inv123',
          ),
        ),
      ]),
    );
  });

  test('execute returns failure state when link is empty', () async {
    final response = GenerateInvitationLinkResponse(
      id: 'inv123',
      link: '',
    );

    when(
      mockRepository.generateInvitationLink(
        request: InvitationRequest(
          contact: testContact,
          medium: testMedium.value,
        ),
      ),
    ).thenAnswer((_) async => response);

    final result = interactor.execute(
      contact: testContact,
      medium: testMedium,
    );

    await expectLater(
      result,
      emitsInOrder([
        const Right(GenerateInvitationLinkLoadingState()),
        const Left(GenerateInvitationLinkIsEmptyState()),
      ]),
    );
  });

  test('execute returns failure state on error', () async {
    when(
      mockRepository.generateInvitationLink(
        request: InvitationRequest(
          contact: testContact,
          medium: testMedium.value,
        ),
      ),
    ).thenThrow(Exception('Test error'));

    final result = interactor.execute(
      contact: testContact,
      medium: testMedium,
    );

    await expectLater(
      result,
      emitsInOrder([
        const Right(GenerateInvitationLinkLoadingState()),
        predicate(
          (dynamic value) =>
              value is Left &&
              value.value is GenerateInvitationLinkFailureState,
        ),
      ]),
    );
  });

  test('execute returns failure state with message on DioException', () async {
    when(
      mockRepository.generateInvitationLink(
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
          data: {'message': 'Test error message'},
        ),
      ),
    );

    final result = interactor.execute(
      contact: testContact,
      medium: testMedium,
    );

    await expectLater(
      result,
      emitsInOrder([
        const Right(GenerateInvitationLinkLoadingState()),
        predicate(
          (dynamic value) =>
              value is Left &&
              value.value is GenerateInvitationLinkFailureState,
        ),
      ]),
    );
  });
}

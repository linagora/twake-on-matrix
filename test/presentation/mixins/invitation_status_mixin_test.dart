import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:fluffychat/data/model/addressbook/address_book.dart';
import 'package:fluffychat/data/model/invitation/invitation_status_response.dart';
import 'package:fluffychat/domain/app_state/invitation/get_invitation_status_state.dart';
import 'package:fluffychat/domain/app_state/invitation/hive_get_invitation_status_state.dart';
import 'package:fluffychat/domain/usecase/contacts/delete_third_party_contact_box_interactor.dart';
import 'package:fluffychat/domain/usecase/contacts/post_address_book_interactor.dart';
import 'package:fluffychat/domain/usecase/invitation/get_invitation_status_interactor.dart';
import 'package:fluffychat/domain/usecase/invitation/hive_delete_invitation_status_interactor.dart';
import 'package:fluffychat/domain/usecase/invitation/hive_get_invitation_status_interactor.dart';
import 'package:fluffychat/presentation/mixins/invitation_status_mixin.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'invitation_status_mixin_test.mocks.dart';

class InvitationStatusMixinTest with InvitationStatusMixin {}

@GenerateMocks([
  HiveGetInvitationStatusInteractor,
  GetInvitationStatusInteractor,
  PostAddressBookInteractor,
  HiveDeleteInvitationStatusInteractor,
  DeleteThirdPartyContactBoxInteractor,
])
void main() {
  late InvitationStatusMixinTest mixinTest;
  late MockHiveGetInvitationStatusInteractor
  mockHiveGetInvitationStatusInteractor;
  late MockGetInvitationStatusInteractor mockGetInvitationStatusInteractor;
  late MockPostAddressBookInteractor mockPostAddressBookInteractor;
  late MockHiveDeleteInvitationStatusInteractor
  mockHiveDeleteInvitationStatusInteractor;
  late MockDeleteThirdPartyContactBoxInteractor
  mockDeleteThirdPartyContactBoxInteractor;

  const testUserId = 'user123';
  const testContactId = 'contact123';
  const testInvitationId = 'inv123';
  const testMatrixId = 'matrix123';
  const testContact = PresentationContact(
    id: testContactId,
    displayName: 'Test Contact',
  );

  setUpAll(() {
    GetIt.instance.reset();
  });

  setUp(() {
    mockHiveGetInvitationStatusInteractor =
        MockHiveGetInvitationStatusInteractor();
    mockGetInvitationStatusInteractor = MockGetInvitationStatusInteractor();
    mockPostAddressBookInteractor = MockPostAddressBookInteractor();
    mockHiveDeleteInvitationStatusInteractor =
        MockHiveDeleteInvitationStatusInteractor();
    mockDeleteThirdPartyContactBoxInteractor =
        MockDeleteThirdPartyContactBoxInteractor();

    GetIt.instance.registerSingleton<HiveGetInvitationStatusInteractor>(
      mockHiveGetInvitationStatusInteractor,
    );
    GetIt.instance.registerSingleton<GetInvitationStatusInteractor>(
      mockGetInvitationStatusInteractor,
    );
    GetIt.instance.registerSingleton<PostAddressBookInteractor>(
      mockPostAddressBookInteractor,
    );
    GetIt.instance.registerSingleton<HiveDeleteInvitationStatusInteractor>(
      mockHiveDeleteInvitationStatusInteractor,
    );
    GetIt.instance.registerSingleton<DeleteThirdPartyContactBoxInteractor>(
      mockDeleteThirdPartyContactBoxInteractor,
    );

    // Add default stubs for all execute methods
    when(
      mockHiveGetInvitationStatusInteractor.execute(
        userId: anyNamed('userId'),
        contactId: anyNamed('contactId'),
      ),
    ).thenAnswer(
      (_) => Stream.value(
        const Right(
          HiveGetInvitationStatusSuccessState(
            contactId: testContactId,
            invitationId: testInvitationId,
          ),
        ),
      ),
    );

    when(
      mockGetInvitationStatusInteractor.execute(
        userId: anyNamed('userId'),
        contactId: anyNamed('contactId'),
        invitationId: anyNamed('invitationId'),
      ),
    ).thenAnswer(
      (_) => Stream.value(
        Right(
          GetInvitationStatusSuccessState(
            invitationStatusResponse: InvitationStatusResponse(
              invitation: Invitation(
                id: testInvitationId,
                matrixId: testMatrixId,
              ),
            ),
          ),
        ),
      ),
    );

    when(
      mockPostAddressBookInteractor.execute(
        addressBooks: anyNamed('addressBooks'),
      ),
    ).thenAnswer(
      (_) => Stream.value(
        Right(
          GetInvitationStatusSuccessState(
            invitationStatusResponse: InvitationStatusResponse(
              invitation: Invitation(id: testInvitationId),
            ),
          ),
        ),
      ),
    );

    when(
      mockHiveDeleteInvitationStatusInteractor.execute(
        userId: anyNamed('userId'),
        contactId: anyNamed('contactId'),
      ),
    ).thenAnswer(
      (_) => Stream.value(
        Right(
          GetInvitationStatusSuccessState(
            invitationStatusResponse: InvitationStatusResponse(
              invitation: Invitation(id: testInvitationId),
            ),
          ),
        ),
      ),
    );

    when(mockDeleteThirdPartyContactBoxInteractor.execute()).thenAnswer(
      (_) => Stream.value(
        Right(
          GetInvitationStatusSuccessState(
            invitationStatusResponse: InvitationStatusResponse(
              invitation: Invitation(id: testInvitationId),
            ),
          ),
        ),
      ),
    );

    mixinTest = InvitationStatusMixinTest();
    mixinTest.getInvitationStatusNotifier.value = const Right(
      GetInvitationStatusInitial(),
    );
  });

  tearDown(() {
    mixinTest.disposeInvitationStatus();

    GetIt.instance.reset();
  });

  group('getInvitationStatus', () {
    test('should not execute on web platform', () {
      PlatformInfos.isTestingForWeb = true;

      mixinTest.getInvitationStatus(
        userId: testUserId,
        contactId: testContactId,
        contact: testContact,
      );

      verifyNever(
        mockHiveGetInvitationStatusInteractor.execute(
          userId: testUserId,
          contactId: testContactId,
        ),
      );
    });

    test('should not execute if not in initial state', () {
      PlatformInfos.isTestingForWeb = false;
      mixinTest.getInvitationStatusNotifier.value = const Right(
        GetInvitationStatusLoadingState(),
      );
      mixinTest.getInvitationStatus(
        userId: testUserId,
        contactId: testContactId,
        contact: testContact,
      );
      verifyNever(
        mockHiveGetInvitationStatusInteractor.execute(
          userId: testUserId,
          contactId: testContactId,
        ),
      );
    });

    test('should execute and handle success state', () async {
      PlatformInfos.isTestingForWeb = false;

      mixinTest.getInvitationStatus(
        userId: testUserId,
        contactId: testContactId,
        contact: testContact,
      );

      await untilCalled(
        mockHiveGetInvitationStatusInteractor.execute(
          userId: testUserId,
          contactId: testContactId,
        ),
      );
      verify(
        mockHiveGetInvitationStatusInteractor.execute(
          userId: testUserId,
          contactId: testContactId,
        ),
      ).called(1);
    });
  });

  group('getInvitationNetworkStatus', () {
    test(
      'should update notifier and handle success state with matrix ID',
      () async {
        final response = InvitationStatusResponse(
          invitation: Invitation(id: testInvitationId, matrixId: testMatrixId),
        );

        when(
          mockGetInvitationStatusInteractor.execute(
            userId: testUserId,
            contactId: testContactId,
            invitationId: testInvitationId,
          ),
        ).thenAnswer(
          (_) => Stream.value(
            Right(
              GetInvitationStatusSuccessState(
                invitationStatusResponse: response,
              ),
            ),
          ),
        );

        when(
          mockPostAddressBookInteractor.execute(
            addressBooks: [
              AddressBook(
                mxid: testMatrixId,
                displayName: testContact.displayName,
              ),
            ],
          ),
        ).thenAnswer(
          (_) => Stream.value(
            Right(
              GetInvitationStatusSuccessState(
                invitationStatusResponse: InvitationStatusResponse(
                  invitation: Invitation(id: testInvitationId),
                ),
              ),
            ),
          ),
        );

        mixinTest.getInvitationNetworkStatus(
          userId: testUserId,
          contactId: testContactId,
          invitationId: testInvitationId,
          contact: testContact,
        );

        await untilCalled(
          mockGetInvitationStatusInteractor.execute(
            userId: testUserId,
            contactId: testContactId,
            invitationId: testInvitationId,
          ),
        );
        verify(
          mockGetInvitationStatusInteractor.execute(
            userId: testUserId,
            contactId: testContactId,
            invitationId: testInvitationId,
          ),
        ).called(1);
      },
    );

    test('should handle 404 error and delete invitation status', () async {
      final dioException = DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 404),
      );

      when(
        mockGetInvitationStatusInteractor.execute(
          userId: testUserId,
          contactId: testContactId,
          invitationId: testInvitationId,
        ),
      ).thenAnswer(
        (_) => Stream.value(
          Left(
            GetInvitationStatusFailureState(
              exception: dioException,
              contactId: testContactId,
              userId: testUserId,
              invitationId: testInvitationId,
            ),
          ),
        ),
      );

      when(
        mockHiveDeleteInvitationStatusInteractor.execute(
          userId: testUserId,
          contactId: testContactId,
        ),
      ).thenAnswer(
        (_) => Stream.value(
          Right(
            GetInvitationStatusSuccessState(
              invitationStatusResponse: InvitationStatusResponse(
                invitation: Invitation(id: testInvitationId),
              ),
            ),
          ),
        ),
      );

      mixinTest.getInvitationNetworkStatus(
        userId: testUserId,
        contactId: testContactId,
        invitationId: testInvitationId,
        contact: testContact,
      );

      await untilCalled(
        mockHiveDeleteInvitationStatusInteractor.execute(
          userId: testUserId,
          contactId: testContactId,
        ),
      );
      verify(
        mockHiveDeleteInvitationStatusInteractor.execute(
          userId: testUserId,
          contactId: testContactId,
        ),
      ).called(1);
    });
  });
}

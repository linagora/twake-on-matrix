import 'package:dartz/dartz.dart';
import 'package:fluffychat/domain/app_state/invitation/store_invitation_status_state.dart';
import 'package:fluffychat/domain/model/invitation/invitation_status.dart';
import 'package:fluffychat/domain/repository/invitation/hive_invitation_status_repository.dart';
import 'package:fluffychat/domain/usecase/invitation/store_invitation_status_interactor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'store_invitation_status_interactor_test.mocks.dart';

@GenerateMocks([HiveInvitationStatusRepository])
void main() {
  late StoreInvitationStatusInteractor interactor;
  late MockHiveInvitationStatusRepository mockRepository;

  setUp(() {
    mockRepository = MockHiveInvitationStatusRepository();
    GetIt.instance.registerSingleton<HiveInvitationStatusRepository>(
      mockRepository,
    );
    interactor = StoreInvitationStatusInteractor();
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  const testUserId = 'user123';
  const testContactId = 'contact123';
  const testInvitationId = 'inv123';

  test(
    'execute returns success state when invitation status is stored successfully',
    () async {
      final invitationStatus = InvitationStatus(
        invitationId: testInvitationId,
        contactId: testContactId,
      );

      when(
        mockRepository.storeInvitationStatus(
          userId: testUserId,
          invitationStatus: invitationStatus,
        ),
      ).thenAnswer((_) async {});

      final result = interactor.execute(
        userId: testUserId,
        contactId: testContactId,
        invitationId: testInvitationId,
      );

      await expectLater(
        result,
        emitsInOrder([
          const Right(StoreInvitationStatusLoadingState()),
          const Right(
            StoreInvitationStatusSuccessState(
              contactId: testContactId,
              userId: testUserId,
              invitationId: testInvitationId,
            ),
          ),
        ]),
      );
    },
  );

  test(
    'execute returns failure state when storing invitation status fails',
    () async {
      final invitationStatus = InvitationStatus(
        invitationId: testInvitationId,
        contactId: testContactId,
      );

      when(
        mockRepository.storeInvitationStatus(
          userId: testUserId,
          invitationStatus: invitationStatus,
        ),
      ).thenThrow(Exception('Failed to store invitation status'));

      final result = interactor.execute(
        userId: testUserId,
        contactId: testContactId,
        invitationId: testInvitationId,
      );

      await expectLater(
        result,
        emitsInOrder([
          const Right(StoreInvitationStatusLoadingState()),
          predicate(
            (dynamic value) =>
                value is Left &&
                value.value is StoreInvitationStatusFailureState,
          ),
        ]),
      );
    },
  );
}

import 'package:dartz/dartz.dart';
import 'package:fluffychat/domain/app_state/invitation/hive_get_invitation_status_state.dart';
import 'package:fluffychat/domain/model/invitation/invitation_status.dart';
import 'package:fluffychat/domain/repository/invitation/hive_invitation_status_repository.dart';
import 'package:fluffychat/domain/usecase/invitation/hive_get_invitation_status_interactor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'hive_get_invitation_status_interactor_test.mocks.dart';

@GenerateMocks([HiveInvitationStatusRepository])
void main() {
  late HiveGetInvitationStatusInteractor interactor;
  late MockHiveInvitationStatusRepository mockRepository;

  setUp(() {
    mockRepository = MockHiveInvitationStatusRepository();
    GetIt.instance.registerSingleton<HiveInvitationStatusRepository>(
      mockRepository,
    );
    interactor = HiveGetInvitationStatusInteractor();
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  const testUserId = 'user123';
  const testContactId = 'contact123';
  const testInvitationId = 'inv123';

  test(
    'execute returns success state when invitation status is retrieved successfully',
    () async {
      final invitationStatus = InvitationStatus(
        contactId: testContactId,
        invitationId: testInvitationId,
      );

      when(
        mockRepository.getInvitationStatus(
          userId: testUserId,
          contactId: testContactId,
        ),
      ).thenAnswer((_) async => invitationStatus);

      final result = interactor.execute(
        userId: testUserId,
        contactId: testContactId,
      );

      await expectLater(
        result,
        emitsInOrder([
          const Right(
            HiveGetInvitationStatusLoadingState(
              userId: testUserId,
              contactId: testContactId,
            ),
          ),
          const Right(
            HiveGetInvitationStatusSuccessState(
              contactId: testContactId,
              invitationId: testInvitationId,
            ),
          ),
        ]),
      );
    },
  );

  test('execute returns failure state on error', () async {
    when(
      mockRepository.getInvitationStatus(
        userId: testUserId,
        contactId: testContactId,
      ),
    ).thenThrow(Exception('Test error'));

    final result = interactor.execute(
      userId: testUserId,
      contactId: testContactId,
    );

    await expectLater(
      result,
      emitsInOrder([
        const Right(
          HiveGetInvitationStatusLoadingState(
            userId: testUserId,
            contactId: testContactId,
          ),
        ),
        predicate(
          (dynamic value) =>
              value is Left &&
              value.value is HiveGetInvitationStatusFailureState,
        ),
      ]),
    );
  });
}

import 'package:dartz/dartz.dart';
import 'package:fluffychat/domain/app_state/invitation/hive_delete_invitation_status_state.dart';
import 'package:fluffychat/domain/repository/invitation/hive_invitation_status_repository.dart';
import 'package:fluffychat/domain/usecase/invitation/hive_delete_invitation_status_interactor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'hive_delete_invitation_status_interactor_test.mocks.dart';

@GenerateMocks([HiveInvitationStatusRepository])
void main() {
  late HiveDeleteInvitationStatusInteractor interactor;
  late MockHiveInvitationStatusRepository mockRepository;

  setUp(() {
    mockRepository = MockHiveInvitationStatusRepository();
    GetIt.instance.registerSingleton<HiveInvitationStatusRepository>(
      mockRepository,
    );
    interactor = HiveDeleteInvitationStatusInteractor();
  });

  tearDown(() {
    GetIt.instance.reset();
    reset(mockRepository);
  });

  const testUserId = 'user123';
  const testContactId = 'contact123';

  test(
    'execute returns success state when invitation status is deleted successfully',
    () async {
      when(
        mockRepository.deleteInvitationStatusByContactId(
          userId: testUserId,
          contactId: testContactId,
        ),
      ).thenAnswer((_) async => {});

      final result = interactor.execute(
        userId: testUserId,
        contactId: testContactId,
      );

      await expectLater(
        result,
        emitsInOrder([
          const Right(HiveDeleteInvitationStatusLoadingState()),
          const Right(
            HiveDeleteInvitationStatusSuccessState(
              userId: testUserId,
              contactId: testContactId,
            ),
          ),
        ]),
      );
    },
  );

  test('execute returns failure state on error', () async {
    when(
      mockRepository.deleteInvitationStatusByContactId(
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
        const Right(HiveDeleteInvitationStatusLoadingState()),
        predicate(
          (dynamic value) =>
              value is Left &&
              value.value is HiveDeleteInvitationStatusFailureState,
        ),
      ]),
    );
  });
}

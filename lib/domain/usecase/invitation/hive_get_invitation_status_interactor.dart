import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/invitation/hive_get_invitation_status_state.dart';
import 'package:fluffychat/domain/repository/invitation/hive_invitation_status_repository.dart';
import 'package:matrix/matrix.dart';

class HiveGetInvitationStatusInteractor {
  final HiveInvitationStatusRepository _hiveInvitationStatusRepository = getIt
      .get<HiveInvitationStatusRepository>();

  Stream<Either<Failure, Success>> execute({
    required String userId,
    required String contactId,
  }) async* {
    try {
      yield Right(
        HiveGetInvitationStatusLoadingState(
          userId: userId,
          contactId: contactId,
        ),
      );

      final res = await _hiveInvitationStatusRepository.getInvitationStatus(
        userId: userId,
        contactId: contactId,
      );

      yield Right(
        HiveGetInvitationStatusSuccessState(
          contactId: contactId,
          invitationId: res.invitationId,
        ),
      );
    } catch (e) {
      Logs().e('HiveGetInvitationStatusInteractor::execute', e);
      yield Left(
        HiveGetInvitationStatusFailureState(
          exception: e,
          contactId: contactId,
          userId: userId,
        ),
      );
    }
  }
}

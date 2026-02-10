import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/invitation/hive_delete_invitation_status_state.dart';
import 'package:fluffychat/domain/repository/invitation/hive_invitation_status_repository.dart';
import 'package:matrix/matrix.dart';

class HiveDeleteInvitationStatusInteractor {
  final HiveInvitationStatusRepository _hiveInvitationStatusRepository = getIt
      .get<HiveInvitationStatusRepository>();

  Stream<Either<Failure, Success>> execute({
    required String userId,
    required String contactId,
  }) async* {
    try {
      yield const Right(HiveDeleteInvitationStatusLoadingState());

      await _hiveInvitationStatusRepository.deleteInvitationStatusByContactId(
        userId: userId,
        contactId: contactId,
      );

      yield Right(
        HiveDeleteInvitationStatusSuccessState(
          userId: userId,
          contactId: contactId,
        ),
      );
    } catch (e) {
      Logs().e('HiveGetInvitationStatusInteractor::execute', e);
      yield Left(
        HiveDeleteInvitationStatusFailureState(
          exception: e,
          userId: userId,
          contactId: contactId,
        ),
      );
    }
  }
}

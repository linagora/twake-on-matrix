import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/invitation/store_invitation_status_state.dart';
import 'package:fluffychat/domain/model/invitation/invitation_status.dart';
import 'package:fluffychat/domain/repository/invitation/hive_invitation_status_repository.dart';
import 'package:matrix/matrix.dart';

class StoreInvitationStatusInteractor {
  final HiveInvitationStatusRepository _hiveInvitationStatusRepository = getIt
      .get<HiveInvitationStatusRepository>();

  Stream<Either<Failure, Success>> execute({
    required String userId,
    required String contactId,
    required String invitationId,
  }) async* {
    try {
      yield const Right(StoreInvitationStatusLoadingState());

      await _hiveInvitationStatusRepository.storeInvitationStatus(
        userId: userId,
        invitationStatus: InvitationStatus(
          contactId: contactId,
          invitationId: invitationId,
        ),
      );

      yield Right(
        StoreInvitationStatusSuccessState(
          contactId: contactId,
          userId: userId,
          invitationId: invitationId,
        ),
      );
    } catch (e) {
      Logs().e('StoreInvitationStatusInteractor::execute', e);
      yield Left(
        StoreInvitationStatusFailureState(
          exception: e,
          contactId: contactId,
          userId: userId,
          invitationId: invitationId,
        ),
      );
    }
  }
}

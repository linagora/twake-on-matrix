import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/invitation/get_invitation_status_state.dart';
import 'package:fluffychat/domain/repository/invitation/invitation_repository.dart';
import 'package:matrix/matrix.dart';

class GetInvitationStatusInteractor {
  final InvitationRepository _invitationRepository = getIt
      .get<InvitationRepository>();

  Stream<Either<Failure, Success>> execute({
    required String userId,
    required String contactId,
    required String invitationId,
  }) async* {
    try {
      yield const Right(GetInvitationStatusLoadingState());
      final res = await _invitationRepository.getInvitationStatus(
        invitationId: invitationId,
      );

      if (res.invitation == null) {
        yield Left(
          GetInvitationStatusEmptyState(
            contactId: contactId,
            userId: userId,
            invitationId: invitationId,
          ),
        );
      }

      yield Right(
        GetInvitationStatusSuccessState(invitationStatusResponse: res),
      );
    } catch (e) {
      Logs().e('GetInvitationStatusInteractor::execute', e);
      yield Left(
        GetInvitationStatusFailureState(
          exception: e,
          contactId: contactId,
          userId: userId,
          invitationId: invitationId,
          message: e is DioException ? e.response?.data['message'] ?? '' : null,
        ),
      );
    }
  }
}

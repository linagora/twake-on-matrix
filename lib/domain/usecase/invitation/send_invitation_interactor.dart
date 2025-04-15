import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/data/model/invitation/invitation_request.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/invitation/send_invitation_state.dart';
import 'package:fluffychat/domain/model/invitation/invitation_medium_enum.dart';
import 'package:fluffychat/domain/repository/invitation/invitation_repository.dart';
import 'package:matrix/matrix.dart';

class SendInvitationInteractor {
  final InvitationRepository _invitationRepository =
      getIt.get<InvitationRepository>();

  Stream<Either<Failure, Success>> execute({
    required String contact,
    required String contactId,
    required InvitationMediumEnum medium,
  }) async* {
    try {
      yield const Right(SendInvitationLoadingState());
      final res = await _invitationRepository.sendInvitation(
        request: InvitationRequest(
          contact: contact,
          medium: medium.value,
        ),
      );
      yield Right(
        SendInvitationSuccessState(
          sendInvitationResponse: res,
          contactId: contactId,
        ),
      );
    } catch (e) {
      Logs().e('SendInvitationInteractor::execute', e);
      if (e is DioException &&
          e.response?.statusCode == 400 &&
          e.response?.data['message'] ==
              'You already sent an invitation to this contact') {
        yield const Left(InvitationAlreadySentState());
        return;
      }
      yield Left(
        SendInvitationFailureState(
          exception: e,
        ),
      );
    }
  }
}

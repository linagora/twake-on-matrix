import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/data/model/invitation/invitation_request.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/invitation/generate_invitation_link_state.dart';
import 'package:fluffychat/domain/app_state/invitation/send_invitation_state.dart';
import 'package:fluffychat/domain/model/invitation/invitation_medium_enum.dart';
import 'package:fluffychat/domain/repository/invitation/invitation_repository.dart';
import 'package:fluffychat/domain/usecase/invitation/constants.dart';
import 'package:matrix/matrix.dart';

class GenerateInvitationLinkInteractor {
  final InvitationRepository _invitationRepository = getIt
      .get<InvitationRepository>();

  Stream<Either<Failure, Success>> execute({
    String? contact,
    InvitationMediumEnum? medium,
  }) async* {
    try {
      yield const Right(GenerateInvitationLinkLoadingState());
      final res = await _invitationRepository.generateInvitationLink(
        request: InvitationRequest(contact: contact, medium: medium?.value),
      );

      if (res.link.isEmpty == true) {
        yield const Left(GenerateInvitationLinkIsEmptyState());
      }
      yield Right(
        GenerateInvitationLinkSuccessState(link: res.link, id: res.id),
      );
    } catch (e) {
      Logs().e('GenerateInvitationLinkInteractor::execute', e);
      if (e is DioException &&
          e.response?.statusCode == 400 &&
          e.response?.data is Map<String, dynamic>) {
        if (e.response?.data['message'] ==
            Constants.alreadySentInvitationMessage) {
          yield const Left(InvitationAlreadySentState());
          return;
        } else if (e.response?.data['message']?.contains(
              Constants.invalidPhoneNumberMessage,
            ) ==
            true) {
          yield const Left(InvalidPhoneNumberFailureState());
          return;
        } else if (e.response?.data['message']?.contains(
              Constants.invalidEmailMessage,
            ) ==
            true) {
          yield const Left(InvalidEmailFailureState());
          return;
        }
      }

      final message = e is DioException
          ? e.response?.data is Map<String, dynamic>
                ? e.response?.data['message']
                : null
          : null;
      yield Left(
        GenerateInvitationLinkFailureState(exception: e, message: message),
      );
      return;
    }
  }
}

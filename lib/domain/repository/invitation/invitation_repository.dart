import 'package:fluffychat/data/model/invitation/generate_invitation_link_response.dart';
import 'package:fluffychat/data/model/invitation/invitation_request.dart';
import 'package:fluffychat/data/model/invitation/invitation_status_response.dart';
import 'package:fluffychat/data/model/invitation/send_invitation_response.dart';

abstract class InvitationRepository {
  Future<SendInvitationResponse> sendInvitation({
    required InvitationRequest request,
  });

  Future<GenerateInvitationLinkResponse> generateInvitationLink({
    required InvitationRequest request,
  });

  Future<InvitationStatusResponse> getInvitationStatus({
    required String invitationId,
  });
}

import 'package:fluffychat/data/datasource/invitation/invitation_datasource.dart';
import 'package:fluffychat/data/model/invitation/generate_invitation_link_response.dart';
import 'package:fluffychat/data/model/invitation/invitation_request.dart';
import 'package:fluffychat/data/model/invitation/send_invitation_response.dart';
import 'package:fluffychat/data/network/invitation/invitation_api.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';

class InvitationDatasourceImpl implements InvitationDatasource {
  final InvitationAPI _invitationAPI = getIt.get<InvitationAPI>();

  @override
  Future<GenerateInvitationLinkResponse> generateInvitationLink({
    required InvitationRequest request,
  }) {
    return _invitationAPI.generateInvitationLink(request: request);
  }

  @override
  Future<SendInvitationResponse> sendInvitation({
    required InvitationRequest request,
  }) {
    return _invitationAPI.sendInvitation(request: request);
  }
}

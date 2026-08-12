import 'package:twake_chat/data/datasource/invitation/invitation_datasource.dart';
import 'package:twake_chat/data/model/invitation/generate_invitation_link_response.dart';
import 'package:twake_chat/data/model/invitation/invitation_request.dart';
import 'package:twake_chat/data/model/invitation/invitation_status_response.dart';
import 'package:twake_chat/data/model/invitation/send_invitation_response.dart';
import 'package:twake_chat/data/network/invitation/invitation_api.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';

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

  @override
  Future<InvitationStatusResponse> getInvitationStatus({
    required String invitationId,
  }) {
    return _invitationAPI.getInvitationStatus(invitationId: invitationId);
  }
}

import 'package:twake_chat/data/datasource/invitation/invitation_datasource.dart';
import 'package:twake_chat/data/model/invitation/generate_invitation_link_response.dart';
import 'package:twake_chat/data/model/invitation/invitation_request.dart';
import 'package:twake_chat/data/model/invitation/invitation_status_response.dart';
import 'package:twake_chat/data/model/invitation/send_invitation_response.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/repository/invitation/invitation_repository.dart';

class InvitationRepositoryImpl implements InvitationRepository {
  final InvitationDatasource _invitationDatasource = getIt
      .get<InvitationDatasource>();

  @override
  Future<GenerateInvitationLinkResponse> generateInvitationLink({
    required InvitationRequest request,
  }) {
    return _invitationDatasource.generateInvitationLink(request: request);
  }

  @override
  Future<SendInvitationResponse> sendInvitation({
    required InvitationRequest request,
  }) {
    return _invitationDatasource.sendInvitation(request: request);
  }

  @override
  Future<InvitationStatusResponse> getInvitationStatus({
    required String invitationId,
  }) {
    return _invitationDatasource.getInvitationStatus(
      invitationId: invitationId,
    );
  }
}

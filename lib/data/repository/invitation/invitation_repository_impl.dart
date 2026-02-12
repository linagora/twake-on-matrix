import 'package:fluffychat/data/datasource/invitation/invitation_datasource.dart';
import 'package:fluffychat/data/model/invitation/generate_invitation_link_response.dart';
import 'package:fluffychat/data/model/invitation/invitation_request.dart';
import 'package:fluffychat/data/model/invitation/invitation_status_response.dart';
import 'package:fluffychat/data/model/invitation/send_invitation_response.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/repository/invitation/invitation_repository.dart';

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

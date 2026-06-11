// data/datasources_impl/invitation_api_datasource_impl.dart

import '03_invitation_exception.dart';
import '04_invitation_api_datasource.dart';
import '06b_invitation_endpoint.dart';

class InvitationApiDataSourceImpl implements InvitationApiDataSource {
  const InvitationApiDataSourceImpl(this._endpoint);

  final InvitationEndpoint _endpoint;

  @override
  Future<String> generateLink(String roomId) async {
    try {
      final response = await _endpoint.generateInvitationLink(
        GenerateInvitationLinkRequest(roomId: roomId),
      );
      return response.invitationLink;
    } catch (e) {
      throw InvitationNetworkException(e);
    }
  }

  @override
  Future<void> sendInvitation({
    required String roomId,
    required String targetUserId,
  }) async {
    try {
      return _endpoint.sendInvitation(
        SendInvitationRequest(roomId: roomId, targetUserId: targetUserId),
      );
    } catch (e) {
      throw InvitationNetworkException(e);
    }
  }
}

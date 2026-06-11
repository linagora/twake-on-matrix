// data/datasources/invitation_api_datasource.dart

abstract class InvitationApiDataSource {
  Future<String> generateLink(String roomId);
  Future<void> sendInvitation({
    required String roomId,
    required String targetUserId,
  });
}

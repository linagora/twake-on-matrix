// data/repositories/invitation_repository_impl.dart

import '01_invitation_link.dart';
import '02_invitation_status.dart';
import '04_invitation_api_datasource.dart';
import '05_invitation_local_datasource.dart';
import '07_invitation_repository.dart';

class InvitationRepositoryImpl implements InvitationRepository {
  const InvitationRepositoryImpl(this._api, this._local);

  final InvitationApiDataSource _api;
  final InvitationLocalDataSource _local;

  @override
  Future<InvitationLink> generateLink(String roomId) async {
    final url = await _api.generateLink(roomId);
    await _local.cacheLink(roomId, url);
    return InvitationLink(
      url: url,
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      roomId: roomId,
    );
  }

  @override
  Future<InvitationStatus> getStatus(String roomId) async {
    final cachedUrl = await _local.getCachedLink(roomId);
    return InvitationStatus(
      isEnabled: true,
      medium: InvitationMedium.link,
      activeLink: cachedUrl != null
          ? InvitationLink(
              url: cachedUrl,
              expiresAt: DateTime.now(),
              roomId: roomId,
            )
          : null,
    );
  }

  @override
  Future<void> sendInvitation({
    required String roomId,
    required String targetUserId,
  }) =>
      _api.sendInvitation(roomId: roomId, targetUserId: targetUserId);
}

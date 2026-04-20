// domain/repositories/invitation_repository.dart

import '01_invitation_link.dart';
import '02_invitation_status.dart';

abstract class InvitationRepository {
  Future<InvitationLink> generateLink(String roomId);
  Future<InvitationStatus> getStatus(String roomId);
  Future<void> sendInvitation({
    required String roomId,
    required String targetUserId,
  });
}

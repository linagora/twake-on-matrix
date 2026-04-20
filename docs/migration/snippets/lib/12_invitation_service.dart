// domain/services/invitation_service.dart

import '01_invitation_link.dart';
import '02_invitation_status.dart';
import '03_invitation_exception.dart';
import '09_generate_invitation_link_usecase.dart';
import '10_get_invitation_status_usecase.dart';
import '11_send_invitation_usecase.dart';

class InvitationService {
  const InvitationService({
    required GenerateInvitationLinkUseCase generateLink,
    required GetInvitationStatusUseCase getStatus,
    required SendInvitationUseCase sendInvitation,
  })  : _generateLink = generateLink,
        _getStatus = getStatus,
        _sendInvitation = sendInvitation;

  final GenerateInvitationLinkUseCase _generateLink;
  final GetInvitationStatusUseCase _getStatus;
  final SendInvitationUseCase _sendInvitation;

  Future<InvitationStatus> getStatus(String roomId) =>
      _getStatus.execute(roomId);

  Future<InvitationLink> generateIfEnabled(String roomId) async {
    final status = await _getStatus.execute(roomId);
    if (!status.isEnabled) throw const InvitationDisabledException();
    return _generateLink.execute(roomId);
  }

  Future<void> invite({required String roomId, required String targetUserId}) =>
      _sendInvitation.execute(
        SendInvitationParams(roomId: roomId, targetUserId: targetUserId),
      );
}

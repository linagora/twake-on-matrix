// domain/usecases/send_invitation_usecase.dart

import '07_invitation_repository.dart';
import 'interfaces/future_usecases.dart';

class SendInvitationParams {
  const SendInvitationParams({
    required this.roomId,
    required this.targetUserId,
  });

  final String roomId;
  final String targetUserId;
}

class SendInvitationUseCase
    extends FutureUseCaseWithParams<void, SendInvitationParams> {
  const SendInvitationUseCase(this._repository);
  final InvitationRepository _repository;

  @override
  Future<void> invoke(SendInvitationParams params) =>
      _repository.sendInvitation(
        roomId: params.roomId,
        targetUserId: params.targetUserId,
      );
}

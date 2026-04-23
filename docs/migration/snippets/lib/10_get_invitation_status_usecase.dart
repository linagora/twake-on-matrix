// domain/usecases/get_invitation_status_usecase.dart

import '02_invitation_status.dart';
import '07_invitation_repository.dart';
import 'interfaces/future_usecases.dart';

class GetInvitationStatusUseCase
    extends FutureUseCaseWithParams<InvitationStatus, String> {
  const GetInvitationStatusUseCase(this._repository);
  final InvitationRepository _repository;

  @override
  Future<InvitationStatus> invoke(String roomId) =>
      _repository.getStatus(roomId);
}

// domain/usecases/generate_invitation_link_usecase.dart

import '01_invitation_link.dart';
import '07_invitation_repository.dart';
import 'interfaces/future_usecases.dart';

class GenerateInvitationLinkUseCase
    extends FutureUseCaseWithParams<InvitationLink, String> {
  const GenerateInvitationLinkUseCase(this._repository);
  final InvitationRepository _repository;

  @override
  Future<InvitationLink> invoke(String roomId) =>
      _repository.generateLink(roomId);
}

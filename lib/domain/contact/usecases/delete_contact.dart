import 'package:twake_chat/domain/contact/repositories/unified_contact_repository.dart';

class DeleteContactUseCase {
  const DeleteContactUseCase(this._repository);

  final UnifiedContactRepository _repository;

  /// Removes the contact of account [userId] identified by [matrixId].
  Future<void> execute(String userId, String matrixId) =>
      _repository.delete(userId, matrixId);
}

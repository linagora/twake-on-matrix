import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/contact/repositories/unified_contact_repository.dart';

class GetUnifiedContactUseCase {
  const GetUnifiedContactUseCase(this._repository);

  final UnifiedContactRepository _repository;

  /// Returns the contact of account [userId] identified by [matrixId].
  Future<UnifiedContact?> execute(String userId, String matrixId) =>
      _repository.getByMatrixId(userId, matrixId);
}

import 'package:twake_chat/domain/contact/repositories/unified_contact_repository.dart';

class DeleteContactUseCase {
  const DeleteContactUseCase(this._repository);

  final UnifiedContactRepository _repository;

  Future<void> execute(String matrixId) => _repository.delete(matrixId);
}

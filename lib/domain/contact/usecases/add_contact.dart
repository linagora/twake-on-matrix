import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/contact/repositories/unified_contact_repository.dart';

/// Persists a contact already built by the service.
///
/// The service is responsible for building the [UnifiedContact] (source values
/// + [ContactResolutionPolicy]); this use case only writes it.
class AddContactUseCase {
  const AddContactUseCase(this._repository);

  final UnifiedContactRepository _repository;

  /// Persists [contact] under its owning account [userId] (its Matrix ID).
  Future<void> execute(String userId, UnifiedContact contact) =>
      _repository.upsert(userId, contact);
}

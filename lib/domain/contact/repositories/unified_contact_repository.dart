import 'package:twake_chat/domain/contact/entities/unified_contact.dart';

/// Domain-facing repository for the unified contact read model.
///
/// It is the only entry point the service uses to read or persist contacts.
abstract class UnifiedContactRepository {
  /// Emits the current contacts immediately, then on every write.
  Stream<List<UnifiedContact>> watchContacts();

  Future<List<UnifiedContact>> getContacts();

  Future<UnifiedContact?> getByMatrixId(String matrixId);

  Future<void> upsert(UnifiedContact contact);

  Future<void> upsertAll(Iterable<UnifiedContact> contacts);

  Future<void> delete(String matrixId);

  Future<void> clear();
}

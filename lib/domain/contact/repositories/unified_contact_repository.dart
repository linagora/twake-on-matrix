import 'package:twake_chat/domain/contact/entities/unified_contact.dart';

/// Domain-facing repository for the unified contact read model.
///
/// It is the only entry point the service uses to read or persist contacts.
///
/// All methods are scoped by `userId` — the Matrix ID of the account that owns
/// the contacts — so a multi-account session never mixes accounts.
abstract class UnifiedContactRepository {
  /// Emits the current contacts of [userId] immediately, then on every write.
  Stream<List<UnifiedContact>> watchContacts(String userId);

  Future<List<UnifiedContact>> getContacts(String userId);

  Future<UnifiedContact?> getByMatrixId(String userId, String matrixId);

  Future<void> upsert(String userId, UnifiedContact contact);

  Future<void> upsertAll(String userId, Iterable<UnifiedContact> contacts);

  Future<void> delete(String userId, String matrixId);

  /// Removes every contact owned by [userId] (account logout).
  Future<void> clear(String userId);
}

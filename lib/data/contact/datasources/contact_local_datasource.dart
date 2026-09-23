import 'package:twake_chat/domain/contact/entities/unified_contact.dart';

/// Local persistence of the [UnifiedContact] read model.
///
/// Interface lives in `data/` (not `domain/`) because it speaks the storage
/// language: the repository and account lifecycle bridge consume it.
abstract class ContactLocalDataSource {
  Future<List<UnifiedContact>> getAll();

  Future<UnifiedContact?> getByMatrixId(String matrixId);

  Future<void> upsert(UnifiedContact contact);

  Future<void> upsertAll(Iterable<UnifiedContact> contacts);

  Future<void> delete(String matrixId);

  Future<void> clear();

  /// Preserves only a cache whose persisted owner matches this account.
  /// Call through the shared contact mutation queue before exposing the store.
  Future<void> prepareForAccount(String? owner);

  /// Emits the current contacts immediately, then on every write.
  Stream<List<UnifiedContact>> watch();
}

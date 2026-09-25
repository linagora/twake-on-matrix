import 'package:twake_chat/domain/contact/entities/unified_contact.dart';

/// Local persistence of the [UnifiedContact] read model.
///
/// Interface lives in `data/` (not `domain/`) because it speaks the storage
/// language: it is consumed by `UnifiedContactRepositoryImpl` only.
///
/// The app supports several Matrix accounts at once, so every entry is scoped
/// by the owning account (`userId`, its Matrix ID): contacts of one account
/// are never read — nor wiped — for another one.
abstract class ContactLocalDataSource {
  Future<List<UnifiedContact>> getAll(String userId);

  Future<UnifiedContact?> getByMatrixId(String userId, String matrixId);

  Future<void> upsert(String userId, UnifiedContact contact);

  Future<void> upsertAll(String userId, Iterable<UnifiedContact> contacts);

  Future<void> delete(String userId, String matrixId);

  /// Removes every contact owned by [userId] (account logout), leaving the
  /// other accounts' data untouched.
  Future<void> clear(String userId);

  /// Emits the current contacts of [userId] immediately, then on every write.
  Stream<List<UnifiedContact>> watch(String userId);
}

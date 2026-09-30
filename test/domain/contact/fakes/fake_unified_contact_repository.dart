import 'dart:async';

import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/contact/repositories/unified_contact_repository.dart';

/// In-memory [UnifiedContactRepository] for unit tests.
///
/// Unit tests exercise a single account, so the store is keyed by `matrixId`
/// and [userId] is accepted to satisfy the account-scoped contract but ignored.
class FakeUnifiedContactRepository implements UnifiedContactRepository {
  final Map<String, UnifiedContact> store = <String, UnifiedContact>{};
  final StreamController<List<UnifiedContact>> _controller =
      StreamController<List<UnifiedContact>>.broadcast();

  @override
  Stream<List<UnifiedContact>> watchContacts(String userId) {
    StreamSubscription<List<UnifiedContact>>? subscription;
    return Stream<List<UnifiedContact>>.multi((controller) {
      subscription = _controller.stream.listen(
        controller.add,
        onError: controller.addError,
      );
      getContacts(userId).then<void>(controller.add).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        controller.addError(error, stackTrace);
      });
      controller.onCancel = () => subscription?.cancel();
    });
  }

  @override
  Future<List<UnifiedContact>> getContacts(String userId) async =>
      store.values.toList();

  @override
  Future<UnifiedContact?> getByMatrixId(String userId, String matrixId) async =>
      store[matrixId];

  @override
  Future<void> upsert(String userId, UnifiedContact contact) async {
    store[contact.matrixId] = contact;
    _controller.add(await getContacts(userId));
  }

  @override
  Future<void> upsertAll(
    String userId,
    Iterable<UnifiedContact> contacts,
  ) async {
    for (final contact in contacts) {
      store[contact.matrixId] = contact;
    }
    _controller.add(await getContacts(userId));
  }

  @override
  Future<void> delete(String userId, String matrixId) async {
    store.remove(matrixId);
    _controller.add(await getContacts(userId));
  }

  @override
  Future<void> clear(String userId) async {
    store.clear();
    _controller.add(await getContacts(userId));
  }

  Future<void> dispose() => _controller.close();
}

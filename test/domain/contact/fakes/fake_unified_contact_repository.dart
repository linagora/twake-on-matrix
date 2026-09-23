import 'dart:async';

import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/contact/repositories/unified_contact_repository.dart';

/// In-memory [UnifiedContactRepository] for unit tests.
class FakeUnifiedContactRepository implements UnifiedContactRepository {
  final Map<String, UnifiedContact> store = <String, UnifiedContact>{};
  final StreamController<List<UnifiedContact>> _controller =
      StreamController<List<UnifiedContact>>.broadcast();

  @override
  Stream<List<UnifiedContact>> watchContacts() {
    StreamSubscription<List<UnifiedContact>>? subscription;
    return Stream<List<UnifiedContact>>.multi((controller) {
      subscription = _controller.stream.listen(
        controller.add,
        onError: controller.addError,
      );
      getContacts().then<void>(controller.add).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        controller.addError(error, stackTrace);
      });
      controller.onCancel = () => subscription?.cancel();
    });
  }

  @override
  Future<List<UnifiedContact>> getContacts() async => store.values.toList();

  @override
  Future<UnifiedContact?> getByMatrixId(String matrixId) async =>
      store[matrixId];

  @override
  Future<void> upsert(UnifiedContact contact) async {
    store[contact.matrixId] = contact;
    _controller.add(await getContacts());
  }

  @override
  Future<void> upsertAll(Iterable<UnifiedContact> contacts) async {
    for (final contact in contacts) {
      store[contact.matrixId] = contact;
    }
    _controller.add(await getContacts());
  }

  @override
  Future<void> delete(String matrixId) async {
    store.remove(matrixId);
    _controller.add(await getContacts());
  }

  @override
  Future<void> clear() async {
    store.clear();
    _controller.add(await getContacts());
  }

  Future<void> dispose() => _controller.close();
}

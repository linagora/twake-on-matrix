import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/contact/datasources/contact_local_datasource.dart';
import 'package:twake_chat/data/contact/repositories/unified_contact_repository_impl.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';

class FakeContactLocalDataSource implements ContactLocalDataSource {
  String? _owner;
  final Map<String, UnifiedContact> _store = <String, UnifiedContact>{};
  final StreamController<List<UnifiedContact>> _controller =
      StreamController<List<UnifiedContact>>.broadcast();

  @override
  Future<List<UnifiedContact>> getAll() async => _store.values.toList();

  @override
  Future<UnifiedContact?> getByMatrixId(String matrixId) async =>
      _store[matrixId];

  @override
  Future<void> upsert(UnifiedContact contact) async {
    _store[contact.matrixId] = contact;
    _controller.add(await getAll());
  }

  @override
  Future<void> upsertAll(Iterable<UnifiedContact> contacts) async {
    for (final contact in contacts) {
      _store[contact.matrixId] = contact;
    }
    _controller.add(await getAll());
  }

  @override
  Future<void> delete(String matrixId) async {
    _store.remove(matrixId);
    _controller.add(await getAll());
  }

  @override
  Future<void> clear() async {
    _store.clear();
    _controller.add(await getAll());
  }

  @override
  Future<void> prepareForAccount(String? owner) async {
    if (owner == null || owner != _owner) await clear();
    _owner = owner;
  }

  @override
  Stream<List<UnifiedContact>> watch() {
    StreamSubscription<List<UnifiedContact>>? subscription;
    return Stream<List<UnifiedContact>>.multi((controller) {
      subscription = _controller.stream.listen(
        controller.add,
        onError: controller.addError,
      );
      getAll().then<void>(controller.add).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        controller.addError(error, stackTrace);
      });
      controller.onCancel = () => subscription?.cancel();
    });
  }

  Future<void> dispose() => _controller.close();
}

void main() {
  late FakeContactLocalDataSource local;
  late UnifiedContactRepositoryImpl repository;

  setUp(() {
    local = FakeContactLocalDataSource();
    repository = UnifiedContactRepositoryImpl(local);
  });

  tearDown(() => local.dispose());

  test('upsert then getByMatrixId returns the stored contact', () async {
    const contact = UnifiedContact(
      matrixId: '@jean:server',
      canonicalDisplayName: 'Jean',
    );

    await repository.upsert(contact);

    expect(await repository.getByMatrixId('@jean:server'), contact);
    expect(await repository.getContacts(), [contact]);
  });

  test('upsertAll stores every contact', () async {
    await repository.upsertAll(const [
      UnifiedContact(matrixId: '@a:server'),
      UnifiedContact(matrixId: '@b:server'),
    ]);

    final contacts = await repository.getContacts();
    expect(
      contacts.map((c) => c.matrixId),
      containsAll(['@a:server', '@b:server']),
    );
  });

  test('delete removes only the targeted contact', () async {
    await repository.upsertAll(const [
      UnifiedContact(matrixId: '@a:server'),
      UnifiedContact(matrixId: '@b:server'),
    ]);

    await repository.delete('@a:server');

    expect(await repository.getByMatrixId('@a:server'), isNull);
    expect(await repository.getByMatrixId('@b:server'), isNotNull);
  });

  test('watchContacts emits the current value then updates', () async {
    await repository.upsert(const UnifiedContact(matrixId: '@a:server'));

    final emissions = repository.watchContacts();
    final iterator = StreamIterator(emissions);

    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current.map((c) => c.matrixId), ['@a:server']);

    await repository.upsert(const UnifiedContact(matrixId: '@b:server'));

    expect(await iterator.moveNext(), isTrue);
    expect(
      iterator.current.map((c) => c.matrixId),
      containsAll(['@a:server', '@b:server']),
    );

    await iterator.cancel();
  });

  test('clear empties the store', () async {
    await repository.upsert(const UnifiedContact(matrixId: '@a:server'));

    await repository.clear();

    expect(await repository.getContacts(), isEmpty);
  });
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/contact/datasources/contact_local_datasource.dart';
import 'package:twake_chat/data/contact/repositories/unified_contact_repository_impl.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';

class FakeContactLocalDataSource implements ContactLocalDataSource {
  final Map<String, Map<String, UnifiedContact>> _store =
      <String, Map<String, UnifiedContact>>{};
  final StreamController<({String userId, List<UnifiedContact> contacts})>
  _controller =
      StreamController<
        ({String userId, List<UnifiedContact> contacts})
      >.broadcast();

  Map<String, UnifiedContact> _owned(String userId) =>
      _store.putIfAbsent(userId, () => <String, UnifiedContact>{});

  @override
  Future<List<UnifiedContact>> getAll(String userId) async =>
      _owned(userId).values.toList();

  @override
  Future<UnifiedContact?> getByMatrixId(String userId, String matrixId) async =>
      _owned(userId)[matrixId];

  @override
  Future<void> upsert(String userId, UnifiedContact contact) async {
    _owned(userId)[contact.matrixId] = contact;
    await _emit(userId);
  }

  @override
  Future<void> upsertAll(
    String userId,
    Iterable<UnifiedContact> contacts,
  ) async {
    for (final contact in contacts) {
      _owned(userId)[contact.matrixId] = contact;
    }
    await _emit(userId);
  }

  @override
  Future<void> delete(String userId, String matrixId) async {
    _owned(userId).remove(matrixId);
    await _emit(userId);
  }

  @override
  Future<void> clear(String userId) async {
    _owned(userId).clear();
    await _emit(userId);
  }

  @override
  Stream<List<UnifiedContact>> watch(String userId) {
    StreamSubscription<({String userId, List<UnifiedContact> contacts})>?
    subscription;
    return Stream<List<UnifiedContact>>.multi((controller) {
      subscription = _controller.stream.listen((event) {
        if (event.userId != userId) return;
        controller.add(event.contacts);
      }, onError: controller.addError);
      getAll(userId).then<void>(controller.add).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        controller.addError(error, stackTrace);
      });
      controller.onCancel = () => subscription?.cancel();
    });
  }

  Future<void> _emit(String userId) async {
    _controller.add((userId: userId, contacts: await getAll(userId)));
  }

  Future<void> dispose() => _controller.close();
}

void main() {
  late FakeContactLocalDataSource local;
  late UnifiedContactRepositoryImpl repository;

  const owner = '@me:server';
  const otherOwner = '@other:server';

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

    await repository.upsert(owner, contact);

    expect(await repository.getByMatrixId(owner, '@jean:server'), contact);
    expect(await repository.getContacts(owner), [contact]);
  });

  test('upsertAll stores every contact', () async {
    await repository.upsertAll(owner, const [
      UnifiedContact(matrixId: '@a:server'),
      UnifiedContact(matrixId: '@b:server'),
    ]);

    final contacts = await repository.getContacts(owner);
    expect(
      contacts.map((c) => c.matrixId),
      containsAll(['@a:server', '@b:server']),
    );
  });

  test('delete removes only the targeted contact', () async {
    await repository.upsertAll(owner, const [
      UnifiedContact(matrixId: '@a:server'),
      UnifiedContact(matrixId: '@b:server'),
    ]);

    await repository.delete(owner, '@a:server');

    expect(await repository.getByMatrixId(owner, '@a:server'), isNull);
    expect(await repository.getByMatrixId(owner, '@b:server'), isNotNull);
  });

  test('watchContacts emits the current value then updates', () async {
    await repository.upsert(owner, const UnifiedContact(matrixId: '@a:server'));

    final emissions = repository.watchContacts(owner);
    final iterator = StreamIterator(emissions);

    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current.map((c) => c.matrixId), ['@a:server']);

    await repository.upsert(owner, const UnifiedContact(matrixId: '@b:server'));

    expect(await iterator.moveNext(), isTrue);
    expect(
      iterator.current.map((c) => c.matrixId),
      containsAll(['@a:server', '@b:server']),
    );

    await iterator.cancel();
  });

  test('clear empties only the owner account', () async {
    await repository.upsert(owner, const UnifiedContact(matrixId: '@a:server'));
    await repository.upsert(
      otherOwner,
      const UnifiedContact(matrixId: '@a:server'),
    );

    await repository.clear(owner);

    expect(await repository.getContacts(owner), isEmpty);
    expect(await repository.getContacts(otherOwner), hasLength(1));
  });

  test('contacts of different accounts are isolated', () async {
    await repository.upsert(
      owner,
      const UnifiedContact(matrixId: '@a:server', canonicalDisplayName: 'Mine'),
    );
    await repository.upsert(
      otherOwner,
      const UnifiedContact(
        matrixId: '@a:server',
        canonicalDisplayName: 'Theirs',
      ),
    );

    expect(
      (await repository.getByMatrixId(
        owner,
        '@a:server',
      ))!.canonicalDisplayName,
      'Mine',
    );
    expect(
      (await repository.getByMatrixId(
        otherOwner,
        '@a:server',
      ))!.canonicalDisplayName,
      'Theirs',
    );

    await repository.delete(owner, '@a:server');

    expect(await repository.getByMatrixId(owner, '@a:server'), isNull);
    expect(await repository.getByMatrixId(otherOwner, '@a:server'), isNotNull);
  });

  test('watchContacts only emits updates of its own account', () async {
    final emissions = repository.watchContacts(owner);
    final iterator = StreamIterator(emissions);

    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current, isEmpty);

    await repository.upsert(
      otherOwner,
      const UnifiedContact(matrixId: '@other-contact:server'),
    );
    await repository.upsert(owner, const UnifiedContact(matrixId: '@a:server'));

    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current.map((c) => c.matrixId), ['@a:server']);

    await iterator.cancel();
  });
}

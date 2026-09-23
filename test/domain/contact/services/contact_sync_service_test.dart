import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_value.dart';
import 'package:twake_chat/domain/contact/policy/contact_resolution_policy.dart';
import 'package:twake_chat/domain/contact/services/contact_sync_service.dart';
import 'package:twake_chat/domain/contact/sources/contact_source.dart';
import 'package:twake_chat/domain/contact/usecases/add_contact.dart';
import 'package:twake_chat/domain/contact/usecases/delete_contact.dart';
import 'package:twake_chat/domain/contact/usecases/get_unified_contact.dart';
import 'package:twake_chat/domain/contact/usecases/sync_contacts.dart';
import 'package:twake_chat/domain/contact/usecases/watch_unified_contacts.dart';

import '../fakes/fake_unified_contact_repository.dart';

class _FakeSource implements ContactSource {
  _FakeSource(this.kind, this.contacts);

  @override
  final ContactSourceKind kind;
  final List<SourcedContact> contacts;

  @override
  Future<List<SourcedContact>> fetch() async => contacts;
}

void main() {
  late FakeUnifiedContactRepository repository;
  late ContactSyncService service;
  const policy = ContactResolutionPolicy();

  ContactSyncService buildService(List<ContactSource> sources) =>
      ContactSyncService(
        repository: repository,
        policy: policy,
        syncContacts: SyncContactsUseCase(
          repository: repository,
          policy: policy,
          sources: sources,
        ),
        watchUnifiedContacts: WatchUnifiedContactsUseCase(repository),
        getUnifiedContact: GetUnifiedContactUseCase(repository),
        addContact: AddContactUseCase(repository),
        deleteContact: DeleteContactUseCase(repository),
      );

  setUp(() {
    repository = FakeUnifiedContactRepository();
    service = buildService(const []);
  });

  tearDown(() => repository.dispose());

  test('refresh merges the sources into the store', () async {
    service = buildService([
      _FakeSource(ContactSourceKind.tomAddressBook, const [
        SourcedContact(
          matrixId: '@a:server',
          value: ContactSourceValue(
            kind: ContactSourceKind.tomAddressBook,
            displayName: 'Alice',
          ),
        ),
      ]),
    ]);

    await service.refresh();

    expect(
      (await service.getContact('@a:server'))?.resolvedDisplayName,
      'Alice',
    );
  });

  test('addContact persists a manual contact', () async {
    await service.addContact(
      matrixId: '@b:server',
      displayName: 'Bob',
      emails: ['bob@server.com'],
    );

    final contact = await service.getContact('@b:server');
    expect(contact, isNotNull);
    expect(contact!.resolvedDisplayName, 'Bob');
    expect(contact.emails, ['bob@server.com']);
  });

  test('deleteContact removes the contact', () async {
    await service.addContact(matrixId: '@c:server', displayName: 'Carol');

    await service.deleteContact('@c:server');

    expect(await service.getContact('@c:server'), isNull);
  });

  test('watchContacts emits the store content', () async {
    await service.addContact(matrixId: '@d:server', displayName: 'Dave');

    final iterator = StreamIterator(service.watchContacts());
    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current.single.matrixId, '@d:server');
    await iterator.cancel();
  });

  test('clear empties the store', () async {
    await service.addContact(matrixId: '@e:server', displayName: 'Eve');

    await service.clear();

    expect(await repository.getContacts(), isEmpty);
  });
}

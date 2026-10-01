import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_value.dart';
import 'package:twake_chat/domain/contact/policy/contact_resolution_policy.dart';
import 'package:twake_chat/domain/contact/services/contact_sync_service.dart';
import 'package:twake_chat/domain/contact/sources/contact_enricher.dart';
import 'package:twake_chat/domain/contact/sources/contact_source.dart';
import 'package:twake_chat/domain/contact/usecases/add_contact.dart';
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
  Future<List<SourcedContact>> fetch(String userId) async => contacts;
}

class _FakeEnricher implements ContactEnricher {
  _FakeEnricher({this.throws = false});

  final bool throws;
  final List<String> enrichedUserIds = <String>[];

  @override
  Future<void> enrich(String userId) async {
    if (throws) throw Exception('enricher down');
    enrichedUserIds.add(userId);
  }
}

void main() {
  const userId = '@me:server';
  late FakeUnifiedContactRepository repository;
  late ContactSyncService service;
  const policy = ContactResolutionPolicy();

  ContactSyncService buildService(List<ContactSource> sources) =>
      ContactSyncService(
        userId: userId,
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

  test('watchContacts emits the store content', () async {
    await service.addContact(matrixId: '@d:server', displayName: 'Dave');

    final iterator = StreamIterator(service.watchContacts());
    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current.single.matrixId, '@d:server');
    await iterator.cancel();
  });

  test(
    'a throwing enricher does not abort the refresh nor the other enrichers',
    () async {
      final failing = _FakeEnricher(throws: true);
      final healthy = _FakeEnricher();
      service = ContactSyncService(
        userId: userId,
        repository: repository,
        policy: policy,
        syncContacts: SyncContactsUseCase(
          repository: repository,
          policy: policy,
          sources: [
            _FakeSource(ContactSourceKind.tomAddressBook, const [
              SourcedContact(
                matrixId: '@a:server',
                value: ContactSourceValue(
                  kind: ContactSourceKind.tomAddressBook,
                  displayName: 'Alice',
                ),
              ),
            ]),
          ],
        ),
        watchUnifiedContacts: WatchUnifiedContactsUseCase(repository),
        getUnifiedContact: GetUnifiedContactUseCase(repository),
        addContact: AddContactUseCase(repository),
        enrichers: [failing, healthy],
      );

      await service.refresh();

      expect(healthy.enrichedUserIds, [userId]);
      expect(
        (await service.getContact('@a:server'))?.resolvedDisplayName,
        'Alice',
      );
    },
  );

  test('clear empties the store', () async {
    await service.addContact(matrixId: '@e:server', displayName: 'Eve');

    await service.clear();

    expect(await repository.getContacts(userId), isEmpty);
  });
}

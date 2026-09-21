import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_value.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/contact/policy/contact_resolution_policy.dart';
import 'package:twake_chat/domain/contact/services/contact_sync_service.dart';
import 'package:twake_chat/domain/contact/sources/contact_source.dart';
import 'package:twake_chat/domain/contact/usecases/add_contact.dart';
import 'package:twake_chat/domain/contact/usecases/delete_contact.dart';
import 'package:twake_chat/domain/contact/usecases/get_unified_contact.dart';
import 'package:twake_chat/domain/contact/usecases/sync_contacts.dart';
import 'package:twake_chat/domain/contact/usecases/watch_unified_contacts.dart';
import 'package:twake_chat/pages/contacts_tab/controllers/contacts_controller.dart';
import 'package:twake_chat/pages/contacts_tab/providers/contacts_providers.dart';

import '../../../domain/contact/fakes/fake_unified_contact_repository.dart';

class _FakeSource implements ContactSource {
  _FakeSource(this.contacts);

  final List<SourcedContact> contacts;

  @override
  ContactSourceKind get kind => ContactSourceKind.tomAddressBook;

  @override
  Future<List<SourcedContact>> fetch() async => contacts;
}

void main() {
  late FakeUnifiedContactRepository repository;
  late ContactSyncService service;
  const policy = ContactResolutionPolicy();

  ContactSyncService buildService({List<ContactSource> sources = const []}) =>
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
    service = buildService();
  });

  tearDown(() => repository.dispose());

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [contactSyncServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Resolves with the first value emitted by the store stream.
  Future<List<UnifiedContact>> firstEmission(ProviderContainer container) {
    final completer = Completer<List<UnifiedContact>>();
    final subscription = container.listen(contactsControllerProvider, (
      previous,
      next,
    ) {
      next.whenData((contacts) {
        if (!completer.isCompleted) completer.complete(contacts);
      });
    }, fireImmediately: true);
    completer.future.whenComplete(subscription.close);
    return completer.future;
  }

  test('build exposes the current store content', () async {
    await repository.upsert(
      const UnifiedContact(
        matrixId: '@a:server',
        canonicalDisplayName: 'Alice',
      ),
    );

    final container = buildContainer();
    final contacts = await firstEmission(container);

    expect(contacts.single.matrixId, '@a:server');
  });

  test('refresh merges sources and pushes them to the stream', () async {
    service = buildService(
      sources: [
        _FakeSource(const [
          SourcedContact(
            matrixId: '@a:server',
            value: ContactSourceValue(
              kind: ContactSourceKind.tomAddressBook,
              displayName: 'Alice',
            ),
          ),
        ]),
      ],
    );

    final container = buildContainer();
    final completer = Completer<List<UnifiedContact>>();
    final subscription = container.listen(contactsControllerProvider, (
      previous,
      next,
    ) {
      next.whenData((contacts) {
        if (contacts.isNotEmpty && !completer.isCompleted) {
          completer.complete(contacts);
        }
      });
    }, fireImmediately: true);

    await container.read(contactsControllerProvider.notifier).refresh();

    final contacts = await completer.future;
    expect(contacts.single.canonicalDisplayName, 'Alice');
    subscription.close();
  });

  test('deleteContact delegates to the service', () async {
    await repository.upsert(const UnifiedContact(matrixId: '@a:server'));
    final container = buildContainer();

    await container
        .read(contactsControllerProvider.notifier)
        .deleteContact('@a:server');

    expect(await repository.getContacts(), isEmpty);
  });

  test('search keyword provider drives the contactsState projection', () async {
    await repository.upsertAll(const [
      UnifiedContact(matrixId: '@a:server', canonicalDisplayName: 'Alice'),
      UnifiedContact(matrixId: '@b:server', canonicalDisplayName: 'Bob'),
    ]);

    final container = buildContainer();
    await firstEmission(container);

    expect(container.read(contactsStateProvider).visibleContacts, hasLength(2));

    container.read(contactsSearchKeywordProvider.notifier).update('ali');

    expect(
      container.read(contactsStateProvider).visibleContacts.single.matrixId,
      '@a:server',
    );
  });
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/contact/policy/contact_resolution_policy.dart';
import 'package:twake_chat/domain/contact/services/contact_sync_service.dart';
import 'package:twake_chat/domain/contact/usecases/add_contact.dart';
import 'package:twake_chat/domain/contact/usecases/delete_contact.dart';
import 'package:twake_chat/domain/contact/usecases/get_unified_contact.dart';
import 'package:twake_chat/domain/contact/usecases/sync_contacts.dart';
import 'package:twake_chat/domain/contact/usecases/watch_unified_contacts.dart';
import 'package:twake_chat/pages/contacts_tab/controllers/contacts_controller.dart';
import 'package:twake_chat/pages/contacts_tab/providers/contacts_providers.dart';
import 'package:twake_chat/pages/contacts_tab/providers/unified_contact_read_providers.dart';

import '../../../domain/contact/fakes/fake_unified_contact_repository.dart';

void main() {
  late FakeUnifiedContactRepository repository;
  late ContactSyncService service;
  const policy = ContactResolutionPolicy();

  setUp(() {
    repository = FakeUnifiedContactRepository();
    service = ContactSyncService(
      repository: repository,
      policy: policy,
      syncContacts: SyncContactsUseCase(
        repository: repository,
        policy: policy,
        sources: const [],
      ),
      watchUnifiedContacts: WatchUnifiedContactsUseCase(repository),
      getUnifiedContact: GetUnifiedContactUseCase(repository),
      addContact: AddContactUseCase(repository),
      deleteContact: DeleteContactUseCase(repository),
    );
  });

  tearDown(() => repository.dispose());

  test('unifiedContact returns the stored contact by matrixId', () async {
    await repository.upsert(
      const UnifiedContact(
        matrixId: '@a:server',
        canonicalDisplayName: 'Alice',
      ),
    );

    final container = ProviderContainer(
      overrides: [contactSyncServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    final completer = Completer<void>();
    final subscription = container.listen(contactsControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasValue && !completer.isCompleted) completer.complete();
    }, fireImmediately: true);
    await completer.future;

    expect(
      container.read(unifiedContactProvider('@a:server'))?.resolvedDisplayName,
      'Alice',
    );
    expect(container.read(unifiedContactProvider('@missing:server')), isNull);
    subscription.close();
  });
}

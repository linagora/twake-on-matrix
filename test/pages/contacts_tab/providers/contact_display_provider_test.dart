import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/contact/datasources/matrix_profile_datasource.dart';
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
import 'package:twake_chat/pages/contacts_tab/providers/matrix_profile_providers.dart';
import 'package:twake_chat/pages/contacts_tab/providers/unified_contact_read_providers.dart';

import '../../../domain/contact/fakes/fake_unified_contact_repository.dart';

class _FakeMatrixProfileDatasource implements MatrixProfileDatasource {
  final List<String> requested = <String>[];

  @override
  Future<MatrixUserProfile?> fetchProfile(String matrixId) async {
    requested.add(matrixId);
    return MatrixUserProfile(
      matrixId: matrixId,
      displayName: 'Network $matrixId',
      avatarUrl: 'mxc://server/$matrixId',
    );
  }
}

void main() {
  late FakeUnifiedContactRepository repository;
  late ContactSyncService service;
  late _FakeMatrixProfileDatasource profileDatasource;
  const policy = ContactResolutionPolicy();

  setUp(() {
    repository = FakeUnifiedContactRepository();
    profileDatasource = _FakeMatrixProfileDatasource();
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

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [
        contactSyncServiceProvider.overrideWithValue(service),
        matrixProfileDatasourceProvider.overrideWithValue(profileDatasource),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> awaitStoreLoaded(ProviderContainer container) {
    final completer = Completer<void>();
    final subscription = container.listen(contactsControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasValue && !completer.isCompleted) completer.complete();
    }, fireImmediately: true);
    completer.future.whenComplete(subscription.close);
    return completer.future;
  }

  test('falls back to the Matrix SDK when the store has no entry', () async {
    final container = buildContainer();

    final contact = await container.read(
      contactDisplayProvider('@a:server').future,
    );

    expect(contact.resolvedDisplayName, 'Network @a:server');
    expect(profileDatasource.requested, ['@a:server']);
  });

  test('prefers the store and does not hit the SDK', () async {
    await repository.upsert(
      const UnifiedContact(
        matrixId: '@a:server',
        canonicalDisplayName: 'Stored Alice',
      ),
    );
    final container = buildContainer();
    await awaitStoreLoaded(container);

    final contact = await container.read(
      contactDisplayProvider('@a:server').future,
    );

    expect(contact.resolvedDisplayName, 'Stored Alice');
    expect(profileDatasource.requested, isEmpty);
  });
}

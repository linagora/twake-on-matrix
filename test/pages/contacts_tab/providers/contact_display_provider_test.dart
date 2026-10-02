import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/contact/datasources/matrix_profile_datasource.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/contact/policy/contact_resolution_policy.dart';
import 'package:twake_chat/domain/contact/services/contact_sync_service.dart';
import 'package:twake_chat/domain/contact/usecases/add_contact.dart';
import 'package:twake_chat/domain/contact/usecases/get_unified_contact.dart';
import 'package:twake_chat/domain/contact/usecases/sync_contacts.dart';
import 'package:twake_chat/domain/contact/usecases/watch_unified_contacts.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_controller.dart';
import 'package:twake_chat/pages/contacts_tab/providers/contacts_providers.dart';
import 'package:twake_chat/pages/contacts_tab/providers/matrix_profile_providers.dart';
import 'package:twake_chat/pages/contacts_tab/providers/unified_contact_read_providers.dart';

import '../../../domain/contact/fakes/fake_unified_contact_repository.dart';

class _FakeMatrixProfileDatasource implements MatrixProfileDatasource {
  _FakeMatrixProfileDatasource({this.unknown = false});

  /// Simulates an unknown user / network failure (datasource returns null).
  final bool unknown;
  final List<String> requested = <String>[];

  @override
  Future<MatrixUserProfile?> fetchProfile(String matrixId) async {
    requested.add(matrixId);
    if (unknown) return null;
    return MatrixUserProfile(
      matrixId: matrixId,
      displayName: 'Network $matrixId',
      avatarUrl: 'mxc://server/$matrixId',
    );
  }
}

void main() {
  const userId = '@me:server';
  late FakeUnifiedContactRepository repository;
  late ContactSyncService service;
  late _FakeMatrixProfileDatasource profileDatasource;
  const policy = ContactResolutionPolicy();

  setUp(() {
    repository = FakeUnifiedContactRepository();
    profileDatasource = _FakeMatrixProfileDatasource();
    service = ContactSyncService(
      userId: userId,
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
    );
  });

  tearDown(() => repository.dispose());

  ProviderContainer buildContainer({String? currentUserId = userId}) {
    final container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue(currentUserId),
        contactSyncServiceProvider.overrideWith((ref, _) => service),
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

  // warmUp: wait for the store stream to emit before the first read; otherwise
  // the first read happens while the store is still loading.
  for (final warmUp in [true, false]) {
    test(
      warmUp
          ? 'prefers the store and does not hit the SDK'
          : 'a one-shot read while the store is loading still prefers it',
      () async {
        await repository.upsert(
          userId,
          const UnifiedContact(
            matrixId: '@a:server',
            canonicalDisplayName: 'Stored Alice',
          ),
        );
        final container = buildContainer();
        if (warmUp) await awaitStoreLoaded(container);

        final contact = await container.read(
          contactDisplayProvider('@a:server').future,
        );

        expect(contact.resolvedDisplayName, 'Stored Alice');
        expect(profileDatasource.requested, isEmpty);
      },
    );
  }

  test('returns an id-only contact when the SDK knows nothing', () async {
    profileDatasource = _FakeMatrixProfileDatasource(unknown: true);
    final container = buildContainer();

    final contact = await container.read(
      contactDisplayProvider('@ghost:server').future,
    );

    expect(contact.resolvedDisplayName, isNull);
    expect(contact.displayNameOrId, '@ghost:server');
  });

  test('resolves before login (no account) through the SDK', () async {
    final container = buildContainer(currentUserId: null);

    final contact = await container.read(
      contactDisplayProvider('@a:server').future,
    );

    expect(contact.resolvedDisplayName, 'Network @a:server');
  });
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart' show Client;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/contact/sources/tom_user_info_source.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_value.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/contact/policy/contact_resolution_policy.dart';
import 'package:twake_chat/domain/contact/services/contact_sync_service.dart';
import 'package:twake_chat/domain/contact/sources/contact_source.dart';
import 'package:twake_chat/domain/contact/usecases/add_contact.dart';
import 'package:twake_chat/domain/contact/usecases/get_unified_contact.dart';
import 'package:twake_chat/domain/contact/usecases/sync_contacts.dart';
import 'package:twake_chat/domain/contact/usecases/watch_unified_contacts.dart';
import 'package:twake_chat/domain/model/user_info/user_info.dart';
import 'package:twake_chat/domain/model/user_info/user_info_visibility.dart';
import 'package:twake_chat/domain/model/user_info/user_info_visibility_request.dart';
import 'package:twake_chat/domain/repository/user_info/user_info_repository.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_controller.dart';
import 'package:twake_chat/pages/contacts_tab/providers/contacts_providers.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

import '../../domain/contact/fakes/fake_unified_contact_repository.dart';
import 'contacts_controller_test.mocks.dart';

class _FakeSource implements ContactSource {
  _FakeSource(this.contacts);

  final List<SourcedContact> contacts;

  @override
  ContactSourceKind get kind => ContactSourceKind.tomAddressBook;

  @override
  Future<List<SourcedContact>> fetch(String userId) async => contacts;
}

class _FakeUserInfoRepository implements UserInfoRepository {
  @override
  Future<UserInfo> getUserInfo(String userId) async =>
      UserInfo(uid: Uri.decodeComponent(userId));

  @override
  Future<UserInfoVisibility> getUserVisibility(String userId) async =>
      UserInfoVisibility();

  @override
  Future<UserInfoVisibility> updateUserInfoVisibility(
    String userId,
    UserInfoVisibilityRequest userInfoVisibility,
  ) async => UserInfoVisibility();
}

@GenerateNiceMocks([MockSpec<Client>()])
void main() {
  const userId = '@me:server';
  late FakeUnifiedContactRepository repository;
  late ContactSyncService service;
  const policy = ContactResolutionPolicy();

  ContactSyncService buildService({List<ContactSource> sources = const []}) =>
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
    service = buildService();
  });

  tearDown(() => repository.dispose());

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue(userId),
        contactSyncServiceProvider.overrideWith((ref, _) => service),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Resolves with the first emission of the store stream, optionally waiting
  /// for one that satisfies [where].
  Future<List<UnifiedContact>> firstEmission(
    ProviderContainer container, {
    bool Function(List<UnifiedContact>)? where,
  }) {
    final completer = Completer<List<UnifiedContact>>();
    final subscription = container.listen(contactsControllerProvider, (
      previous,
      next,
    ) {
      next.whenData((contacts) {
        if (completer.isCompleted) return;
        if (where == null || where(contacts)) completer.complete(contacts);
      });
    }, fireImmediately: true);
    completer.future.whenComplete(subscription.close);
    return completer.future;
  }

  test('build exposes the current store content', () async {
    await repository.upsert(
      userId,
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

    await container.read(contactsControllerProvider.notifier).refresh();

    final contacts = await firstEmission(
      container,
      where: (contacts) => contacts.isNotEmpty,
    );
    expect(contacts.single.canonicalDisplayName, 'Alice');
  });

  test('search keyword provider drives the contactsState projection', () async {
    await repository.upsertAll(userId, const [
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

  group('real provider wiring', () {
    /// Only the leaf dependencies (store, sources, enricher) are faked:
    /// `activeMatrixClient → currentUserId → contactSyncService → use cases`
    /// is the real generated wiring.
    ProviderContainer buildWiredContainer({
      List<ContactSource> sources = const [],
    }) {
      final container = ProviderContainer(
        overrides: [
          unifiedContactRepositoryProvider.overrideWithValue(repository),
          contactSourcesProvider.overrideWithValue(sources),
          tomUserInfoEnricherProvider.overrideWith(
            (ref) => TomUserInfoSource(
              repository: repository,
              userInfoRepository: _FakeUserInfoRepository(),
              policy: policy,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('re-pushing the same client after login updates currentUserId', () {
      final container = buildWiredContainer();
      final client = MockClient();
      when(client.userID).thenReturn(null);

      container.read(activeMatrixClientProvider.notifier).setClient(client);
      expect(container.read(currentUserIdProvider), isNull);

      // The SDK mutates `userID` in place on the same Client instance at
      // login: the provider must still notify its consumers.
      when(client.userID).thenReturn(userId);
      container.read(activeMatrixClientProvider.notifier).setClient(client);

      expect(container.read(currentUserIdProvider), userId);
    });

    test(
      'refresh through the real wiring keeps the stored enrichment values',
      () async {
        const matrixId = '@a:server';
        await repository.upsert(
          userId,
          const UnifiedContact(
            matrixId: matrixId,
            canonicalDisplayName: 'Alice',
            sources: [
              ContactSourceValue(
                kind: ContactSourceKind.tomAddressBook,
                displayName: 'Alice',
              ),
              ContactSourceValue(
                kind: ContactSourceKind.tomUserInfo,
                displayName: 'Alice (LDAP)',
                avatarUrl: 'mxc://server/alice',
              ),
            ],
          ),
        );
        final container = buildWiredContainer(
          sources: [
            _FakeSource(const [
              SourcedContact(
                matrixId: matrixId,
                value: ContactSourceValue(
                  kind: ContactSourceKind.tomAddressBook,
                  displayName: 'Alice',
                ),
              ),
            ]),
          ],
        );
        final client = MockClient();
        when(client.userID).thenReturn(userId);
        container.read(activeMatrixClientProvider.notifier).setClient(client);

        await container.read(contactsControllerProvider.notifier).refresh();

        final contact = await repository.getByMatrixId(userId, matrixId);
        expect(
          contact!.sources.map((value) => value.kind),
          containsAll(<ContactSourceKind>[
            ContactSourceKind.tomAddressBook,
            ContactSourceKind.tomUserInfo,
          ]),
        );
        expect(contact.avatarUrl, 'mxc://server/alice');
      },
    );
  });
}

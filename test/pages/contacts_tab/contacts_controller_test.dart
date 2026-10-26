import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/contact/sources/tom_user_info_source.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_value.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/contact/policy/contact_resolution_policy.dart';
import 'package:twake_chat/domain/contact/services/contact_sync_service.dart';
import 'package:twake_chat/domain/contact/sources/contact_source.dart';
import 'package:twake_chat/domain/contact/sources/phonebook_resolver.dart';
import 'package:twake_chat/domain/model/user_info/user_info.dart';
import 'package:twake_chat/domain/model/user_info/user_info_visibility.dart';
import 'package:twake_chat/domain/model/user_info/user_info_visibility_request.dart';
import 'package:twake_chat/domain/repository/user_info/user_info_repository.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_controller.dart';
import 'package:twake_chat/pages/contacts_tab/providers/contacts_providers.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/providers/active_user_id_provider.dart';

import '../../domain/contact/fakes/build_contact_sync_service.dart';
import '../../domain/contact/fakes/fake_unified_contact_repository.dart';

class _FakeSource implements ContactSource {
  _FakeSource(this.contacts);

  final List<SourcedContact> contacts;

  @override
  ContactSourceKind get kind => ContactSourceKind.tomAddressBook;

  @override
  Future<List<SourcedContact>> fetch(String userId) async => contacts;
}

/// Answers only once the test opens its gate (a slow ToM address book).
class _GatedSource implements ContactSource {
  final Completer<void> gate = Completer<void>();

  @override
  ContactSourceKind get kind => ContactSourceKind.tomAddressBook;

  @override
  Future<List<SourcedContact>> fetch(String userId) async {
    await gate.future;
    return const [
      SourcedContact(
        matrixId: '@a:server',
        value: ContactSourceValue(
          kind: ContactSourceKind.tomAddressBook,
          displayName: 'Alice',
        ),
      ),
    ];
  }
}

class _NoopPhonebookResolver implements PhonebookResolver {
  @override
  Future<void> resolve(String userId) async {}

  @override
  Future<void> cancel() async {}
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

void main() {
  const userId = '@me:server';
  late FakeUnifiedContactRepository repository;
  late ContactSyncService service;
  const policy = ContactResolutionPolicy();

  ContactSyncService buildService({List<ContactSource> sources = const []}) =>
      buildContactSyncService(
        userId: userId,
        repository: repository,
        sources: sources,
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
    /// `activeUserId → currentUserId → contactSyncService → use cases`
    /// is the real generated wiring.
    ProviderContainer buildWiredContainer({
      List<ContactSource> sources = const [],
    }) {
      final container = ProviderContainer(
        overrides: [
          activeMatrixClientProvider.overrideWithValue(null),
          activeUserIdProvider.overrideWith((ref) => ref.watch(_activeUser)),
          unifiedContactRepositoryProvider.overrideWithValue(repository),
          contactSourcesProvider.overrideWithValue(sources),
          phonebookResolverProvider.overrideWithValue(_NoopPhonebookResolver()),
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

    test(
      'refresh through the real wiring keeps the stored enrichment values',
      () async {
        const matrixId = '@a:server';
        await repository.upsert(
          userId,
          UnifiedContact(
            matrixId: matrixId,
            canonicalDisplayName: 'Alice',
            sources: [
              const ContactSourceValue(
                kind: ContactSourceKind.tomAddressBook,
                displayName: 'Alice',
              ),
              ContactSourceValue(
                kind: ContactSourceKind.tomUserInfo,
                displayName: 'Alice (LDAP)',
                avatarUrl: 'mxc://server/alice',
                // Fresh: the enricher must not refetch (and replace) it.
                updatedAt: DateTime.now().toUtc(),
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
        container.read(_activeUser.notifier).set(userId);

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

    test(
      'a refresh outliving an account switch writes into no store',
      () async {
        final source = _GatedSource();
        final container = buildWiredContainer(sources: [source]);
        final active = container.read(_activeUser.notifier);
        active.set(userId);

        final refresh = container
            .read(contactsControllerProvider.notifier)
            .refresh();
        await pumpEventQueue();
        // The user switches to B while A's address book is still loading.
        active.set('@other:server');
        source.gate.complete();
        await refresh;

        expect(await repository.getContacts(userId), isEmpty);
        expect(await repository.getContacts('@other:server'), isEmpty);
      },
    );
  });
}

/// The signed-in account of the wired container, switched by the tests.
class _ActiveUser extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? userId) => state = userId;
}

final _activeUser = NotifierProvider<_ActiveUser, String?>(_ActiveUser.new);

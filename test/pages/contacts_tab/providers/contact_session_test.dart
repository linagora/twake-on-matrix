import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:matrix/matrix.dart' show Client;
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/contact/datasources_impl/contact_local_datasource_impl.dart';
import 'package:twake_chat/data/contact/repositories/unified_contact_repository_impl.dart';
import 'package:twake_chat/data/contact/sources/tom_user_info_source.dart';
import 'package:twake_chat/data/hive/hive_collection_tom_database.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_value.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/contact/policy/contact_resolution_policy.dart';
import 'package:twake_chat/domain/contact/sources/contact_source.dart';
import 'package:twake_chat/domain/model/user_info/user_info.dart';
import 'package:twake_chat/domain/repository/user_info/user_info_repository.dart';
import 'package:twake_chat/pages/contacts_tab/providers/contacts_providers.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/providers/contact_session_controller.dart';

class _Client extends Mock implements Client {
  _Client(this.userID);

  @override
  final String userID;

  @override
  Uri get homeserver => Uri.parse('https://server');
}

class _Source implements ContactSource {
  _Source(this.result);

  final Future<List<SourcedContact>> result;
  final started = Completer<void>();
  int calls = 0;
  bool offline = false;

  @override
  ContactSourceKind get kind => ContactSourceKind.tomAddressBook;

  @override
  Future<List<SourcedContact>> fetch() {
    calls++;
    if (!started.isCompleted) started.complete();
    if (offline) return Future.error(const SocketException('offline'));
    return result;
  }
}

class _UserInfo extends Mock implements UserInfoRepository {
  final started = Completer<void>();
  final List<String> calls = [];
  Completer<UserInfo>? response;

  @override
  Future<UserInfo> getUserInfo(String userId) {
    calls.add(Uri.decodeComponent(userId));
    if (!started.isCompleted) started.complete();
    return response?.future ??
        Future.value(const UserInfo(displayName: 'Directory'));
  }
}

class _LocalStore extends ContactLocalDataSourceImpl {
  _LocalStore({required super.database});

  Completer<void>? writeStarted;
  Completer<void>? releaseWrite;

  @override
  Future<void> upsertAll(Iterable<UnifiedContact> contacts) async {
    final release = releaseWrite;
    releaseWrite = null;
    if (release != null) {
      writeStarted!.complete();
      await release.future;
    }
    await super.upsertAll(contacts);
  }
}

List<SourcedContact> _contacts(String account, {int count = 1}) => [
  for (var i = 0; i < count; i++)
    SourcedContact(
      matrixId: '@$i:$account',
      value: const ContactSourceValue(
        kind: ContactSourceKind.tomAddressBook,
        displayName: 'Addressbook',
      ),
    ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;
  late _LocalStore local;
  late UnifiedContactRepositoryImpl repository;
  late ProviderContainer container;
  late Client accountA;
  late Client accountB;
  late _Source sourceA;
  late _Source sourceB;
  late _UserInfo userInfo;

  ProviderContainer createContainer() => ProviderContainer(
    overrides: [
      contactLocalDataSourceProvider.overrideWith((ref) {
        ref.onDispose(local.dispose);
        return local;
      }),
      unifiedContactRepositoryProvider.overrideWithValue(repository),
      contactSourcesProvider.overrideWith((ref) {
        final client = ref.watch(activeMatrixClientProvider);
        return identical(client, accountA) ? [sourceA] : [sourceB];
      }),
      tomUserInfoEnricherProvider.overrideWith(
        (ref) => TomUserInfoSource(
          repository: repository,
          userInfoRepository: userInfo,
          policy: const ContactResolutionPolicy(),
        ),
      ),
    ],
  );

  Future<void> reopen() async {
    container.dispose();
    local.dispose();
    await Hive.close();
    final database = HiveCollectionToMDatabase('session', directory.path);
    await database.open();
    local = _LocalStore(database: database);
    repository = UnifiedContactRepositoryImpl(local);
    container = createContainer();
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('contact_session_');
    Hive.init(directory.path);
    final database = HiveCollectionToMDatabase('session', directory.path);
    await database.open();
    local = _LocalStore(database: database);
    repository = UnifiedContactRepositoryImpl(local);
    accountA = _Client('@a:server');
    accountB = _Client('@b:server');
    sourceA = _Source(Future.value(_contacts('a')));
    sourceB = _Source(Future.value(_contacts('b')));
    userInfo = _UserInfo();
    container = createContainer();
  });

  tearDown(() async {
    container.dispose();
    local.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<void> activate(Client client) async {
    await container
        .read(contactSessionControllerProvider)
        .transition(client, () async {});
    await container.read(contactSyncServiceProvider).refresh();
  }

  test('slow A cannot overwrite B or start its enrichment', () async {
    final responseA = Completer<List<SourcedContact>>();
    sourceA = _Source(responseA.future);
    container.read(activeMatrixClientProvider.notifier).setClient(accountA);
    final serviceA = container.read(contactSyncServiceProvider);
    final refreshA = serviceA.refresh();
    await sourceA.started.future;

    await activate(accountB);
    responseA.complete(_contacts('a'));
    await refreshA;
    await serviceA.addContact(matrixId: '@late:a');
    await serviceA.deleteContact('@0:b');

    expect((await repository.getContacts()).map((c) => c.matrixId), ['@0:b']);
    expect(userInfo.calls, ['@0:b']);
    expect(sourceA.calls, 1);
    expect(sourceB.calls, 1);
  });

  test('slow A enrichment stops before the next HTTP call after B', () async {
    sourceA = _Source(Future.value(_contacts('a', count: 3)));
    final response = Completer<UserInfo>();
    userInfo.response = response;
    container.read(activeMatrixClientProvider.notifier).setClient(accountA);
    final refreshA = container.read(contactSyncServiceProvider).refresh();
    await userInfo.started.future;

    userInfo.response = null;
    await activate(accountB);
    response.complete(const UserInfo(displayName: 'Late A'));
    await refreshA;

    expect((await repository.getContacts()).map((c) => c.matrixId), ['@0:b']);
    expect(userInfo.calls, ['@0:a', '@0:b']);
  });

  test('delete during enrichment is not resurrected by its response', () async {
    final response = Completer<UserInfo>();
    userInfo.response = response;
    container.read(activeMatrixClientProvider.notifier).setClient(accountA);
    final service = container.read(contactSyncServiceProvider);
    final refresh = service.refresh();
    await userInfo.started.future;

    await service.deleteContact('@0:a');
    response.complete(const UserInfo(displayName: 'Late A'));
    await refresh;

    expect(await repository.getContacts(), isEmpty);
  });

  test('clear waits for the active Hive mutation before B writes', () async {
    local.writeStarted = Completer<void>();
    final release = Completer<void>();
    local.releaseWrite = release;
    container.read(activeMatrixClientProvider.notifier).setClient(accountA);
    final refreshA = container.read(contactSyncServiceProvider).refresh();
    await local.writeStarted!.future;
    var configuredB = false;
    final switchB = container
        .read(contactSessionControllerProvider)
        .transition(accountB, () async => configuredB = true);
    await Future<void>.delayed(Duration.zero);
    expect(configuredB, isFalse);

    release.complete();
    await refreshA;
    await switchB;
    await container.read(contactSyncServiceProvider).refresh();

    expect(configuredB, isTrue);
    expect((await repository.getContacts()).map((c) => c.matrixId), ['@0:b']);
  });

  test(
    'logout stays empty after a delayed refresh and rejects later refreshes',
    () async {
      final response = Completer<List<SourcedContact>>();
      sourceA = _Source(response.future);
      container.read(activeMatrixClientProvider.notifier).setClient(accountA);
      final refresh = container.read(contactSyncServiceProvider).refresh();
      await sourceA.started.future;

      await container
          .read(contactSessionControllerProvider)
          .transition(null, () async {});
      response.complete(_contacts('a'));
      await refresh;
      await container.read(contactSyncServiceProvider).refresh();

      expect(await repository.getContacts(), isEmpty);
      expect(sourceB.calls, 0);
      expect(userInfo.calls, isEmpty);
    },
  );

  test('provider disposal invalidates a delayed refresh', () async {
    final response = Completer<List<SourcedContact>>();
    sourceA = _Source(response.future);
    container.read(activeMatrixClientProvider.notifier).setClient(accountA);
    final refresh = container.read(contactSyncServiceProvider).refresh();
    await sourceA.started.future;

    container.invalidate(contactSyncServiceProvider);
    response.complete(_contacts('a'));
    await refresh;

    expect(await repository.getContacts(), isEmpty);
    expect(userInfo.calls, isEmpty);
  });

  test(
    'concurrent refreshes in one session share one source and enrichment',
    () async {
      final response = Completer<List<SourcedContact>>();
      sourceA = _Source(response.future);
      container.read(activeMatrixClientProvider.notifier).setClient(accountA);
      final service = container.read(contactSyncServiceProvider);
      final first = service.refresh();
      final second = service.refresh();
      await sourceA.started.future;
      response.complete(_contacts('a'));
      await Future.wait([first, second]);

      expect(identical(first, second), isTrue);
      expect(sourceA.calls, 1);
      expect(userInfo.calls, ['@0:a']);
    },
  );

  test(
    'startup hides unowned cache until configuration and clear finish',
    () async {
      await repository.upsert(const UnifiedContact(matrixId: '@cached:other'));
      final inactive = container.read(contactSyncServiceProvider);
      expect(await inactive.watchContacts().first, isEmpty);
      expect(await inactive.getContact('@cached:other'), isNull);

      final configured = Completer<void>();
      final releaseConfiguration = Completer<void>();
      final fetched = Completer<List<SourcedContact>>();
      sourceB = _Source(fetched.future);
      final startup = container
          .read(contactSessionControllerProvider)
          .transition(accountB, () async {
            configured.complete();
            await releaseConfiguration.future;
          }, force: true);
      await configured.future;
      expect(container.read(activeMatrixClientProvider), isNull);
      expect(sourceB.calls, 0);

      releaseConfiguration.complete();
      await startup;
      expect(container.read(activeMatrixClientProvider), same(accountB));
      expect(await repository.getContacts(), isEmpty);
      await sourceB.started.future;
      fetched.complete(_contacts('b'));
      await container.read(contactSyncServiceProvider).refresh();
      expect((await repository.getContacts()).map((c) => c.matrixId), ['@0:b']);
    },
  );

  test(
    'same account is skipped but an account replacing its index is activated',
    () async {
      final clients = <Client>[accountA, accountB];
      await activate(clients.first);
      var configurations = 0;
      await container
          .read(contactSessionControllerProvider)
          .transition(accountA, () async => configurations++);
      clients.removeAt(0);
      await container
          .read(contactSessionControllerProvider)
          .transition(clients.first, () async => configurations++);
      await container.read(contactSyncServiceProvider).refresh();

      expect(configurations, 1);
      expect(container.read(activeMatrixClientProvider), same(accountB));
      expect((await repository.getContacts()).map((c) => c.matrixId), ['@0:b']);
      expect(sourceA.calls, 1);
      expect(sourceB.calls, 1);
    },
  );

  test('reopened Hive preserves the same owner cache while offline', () async {
    await activate(accountA);
    final cached = await repository.getContacts();
    expect(cached, isNotEmpty);
    await reopen();
    accountA = _Client('@a:server');
    sourceA = _Source(Future.value([]))..offline = true;
    userInfo.calls.clear();

    await container
        .read(contactSessionControllerProvider)
        .transition(accountA, () async {}, force: true);
    final refresh = container.read(contactSyncServiceProvider).refresh();
    expect(
      await container.read(contactSyncServiceProvider).watchContacts().first,
      cached,
    );
    await refresh;

    expect(await repository.getContacts(), cached);
    expect(sourceA.calls, 1);
    expect(userInfo.calls, isEmpty);
  });

  test('reopened Hive clears an unknown owner while offline', () async {
    await repository.upsert(const UnifiedContact(matrixId: '@old:server'));
    await reopen();
    sourceA = _Source(Future.value([]))..offline = true;

    await activate(accountA);

    expect(await repository.getContacts(), isEmpty);
    expect(userInfo.calls, isEmpty);
  });

  test(
    'clear and refresh retain ownership across an offline restart',
    () async {
      await activate(accountA);
      final service = container.read(contactSyncServiceProvider);
      await service.clear();
      expect(await repository.getContacts(), isEmpty);
      await service.refresh();
      final cached = await repository.getContacts();
      expect(cached, isNotEmpty);
      await reopen();
      sourceA = _Source(Future.value([]))..offline = true;

      await activate(accountA);

      expect(await repository.getContacts(), cached);
    },
  );

  test('reopened Hive clears a different owner while offline', () async {
    await activate(accountA);
    await reopen();
    sourceB = _Source(Future.value([]))..offline = true;
    userInfo.calls.clear();

    await activate(accountB);

    expect(await repository.getContacts(), isEmpty);
    expect(userInfo.calls, isEmpty);
  });

  test(
    'logout clears before configuration closes Hive and stays empty',
    () async {
      await activate(accountA);
      await container
          .read(contactSessionControllerProvider)
          .transition(null, Hive.close);
      await reopen();
      sourceA = _Source(Future.value([]))..offline = true;

      expect(await repository.getContacts(), isEmpty);
      await activate(accountA);
      expect(await repository.getContacts(), isEmpty);
    },
  );

  test(
    'dispose during configuration never reads Ref or Hive afterwards',
    () async {
      final configured = Completer<void>();
      final release = Completer<void>();
      final transition = container
          .read(contactSessionControllerProvider)
          .transition(accountA, () async {
            configured.complete();
            await release.future;
          });
      await configured.future;
      container.dispose();
      container = ProviderContainer();
      await Hive.close();
      release.complete();

      await transition;
      expect(sourceA.calls, 0);
      expect(userInfo.calls, isEmpty);
    },
  );

  test(
    'queued account changes configure serially and publish the last account',
    () async {
      final firstConfigured = Completer<void>();
      final release = Completer<void>();
      final order = <String>[];
      final controller = container.read(contactSessionControllerProvider);
      final first = controller.transition(accountA, () async {
        order.add('A');
        firstConfigured.complete();
        await release.future;
      });
      await firstConfigured.future;
      final second = controller.transition(
        accountB,
        () async => order.add('B'),
      );
      expect(order, ['A']);
      release.complete();
      await Future.wait([first, second]);
      await container.read(contactSyncServiceProvider).refresh();

      expect(order, ['A', 'B']);
      expect(container.read(activeMatrixClientProvider), same(accountB));
      expect((await repository.getContacts()).map((c) => c.matrixId), ['@0:b']);
    },
  );
}

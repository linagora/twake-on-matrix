import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/contact/datasources/matrix_profile_datasource.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/contact/services/contact_sync_service.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_controller.dart';
import 'package:twake_chat/pages/contacts_tab/providers/contacts_providers.dart';
import 'package:twake_chat/pages/contacts_tab/providers/matrix_profile_providers.dart';
import 'package:twake_chat/pages/contacts_tab/providers/unified_contact_read_providers.dart';

import '../../../domain/contact/fakes/build_contact_sync_service.dart';
import '../../../domain/contact/fakes/fake_unified_contact_repository.dart';

void main() {
  const userId = '@me:server';
  late FakeUnifiedContactRepository repository;
  late ContactSyncService service;

  setUp(() {
    repository = FakeUnifiedContactRepository();
    service = buildContactSyncService(userId: userId, repository: repository);
  });

  tearDown(() => repository.dispose());

  test('unifiedContact returns the stored contact by matrixId', () async {
    await repository.upsert(
      userId,
      const UnifiedContact(
        matrixId: '@a:server',
        canonicalDisplayName: 'Alice',
      ),
    );

    final container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue(userId),
        contactSyncServiceProvider.overrideWith((ref, _) => service),
      ],
    );
    addTearDown(container.dispose);

    final subscription = container.listen(
      unifiedContactIndexProvider,
      (_, _) {},
    );
    await container.read(accountContactsProvider(userId).future);

    expect(
      container.read(unifiedContactProvider('@a:server'))?.resolvedDisplayName,
      'Alice',
    );
    expect(container.read(unifiedContactProvider('@missing:server')), isNull);
    subscription.close();
  });
  group('account changes', () {
    late FakeUnifiedContactRepository repositoryB;
    late Map<String, ContactSyncService> services;
    late ProviderContainer container;
    final currentUser = NotifierProvider<_CurrentUser, String?>(
      _CurrentUser.new,
    );

    String? nameOf(String matrixId) =>
        container.read(unifiedContactProvider(matrixId))?.resolvedDisplayName;

    /// Waits until the index serves [matrixId] (or not).
    Future<void> settle() => Future<void>.delayed(Duration.zero);

    setUp(() async {
      repositoryB = FakeUnifiedContactRepository();
      await repository.upsert(
        userId,
        const UnifiedContact(matrixId: '@x:server', canonicalDisplayName: 'X'),
      );
      services = {
        userId: service,
        '@other:server': buildContactSyncService(
          userId: '@other:server',
          repository: repositoryB,
        ),
      };
      container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWith((ref) => ref.watch(currentUser)),
          contactSyncServiceProvider.overrideWith((ref, id) => services[id]!),
          matrixProfileDatasourceProvider.overrideWithValue(_KnowsNobody()),
        ],
      );
      // Keep the whole chain alive like the app does.
      container.listen(unifiedContactIndexProvider, (_, _) {});
      await settle();
    });

    tearDown(() async {
      container.dispose();
      await repositoryB.dispose();
    });

    test('switching A to B never serves A, loading or loaded', () async {
      expect(nameOf('@x:server'), 'X');

      container.read(currentUser.notifier).set('@other:server');
      // B's store has not emitted yet: nothing of A, through the index...
      expect(nameOf('@x:server'), isNull);
      // ...nor through contactDisplay (which then asks the SDK: no name).
      expect(
        (await container.read(
          contactDisplayProvider('@x:server').future,
        )).resolvedDisplayName,
        isNull,
      );

      await settle();
      expect(nameOf('@x:server'), isNull);
      expect(
        (await container.read(
          contactDisplayProvider('@x:server').future,
        )).resolvedDisplayName,
        isNull,
      );
    });

    test('logout serves nothing of the account, not even for a tick', () async {
      expect(nameOf('@x:server'), 'X');

      container.read(currentUser.notifier).set(null);

      expect(nameOf('@x:server'), isNull);
      await settle();
      expect(nameOf('@x:server'), isNull);
    });

    test('same account re-subscribed keeps the previous list served', () async {
      expect(nameOf('@x:server'), 'X');
      final seen = <String?>[];
      container.listen(unifiedContactProvider('@x:server'), (_, next) {
        seen.add(next?.resolvedDisplayName);
      });

      container.invalidate(contactsControllerProvider);
      expect(nameOf('@x:server'), 'X');
      await settle();
      expect(nameOf('@x:server'), 'X');
      expect(seen, isNot(contains(null)));
    });

    test(
      'first load and a re-login of the same account serve the list',
      () async {
        container.read(currentUser.notifier).set(null);
        await settle();
        container.read(currentUser.notifier).set(userId);
        await settle();

        expect(nameOf('@x:server'), 'X');
      },
    );
  });
}

class _KnowsNobody implements MatrixProfileDatasource {
  @override
  Future<MatrixUserProfile?> fetchProfile(
    String matrixId, {
    bool fresh = false,
  }) async => null;
}

class _CurrentUser extends Notifier<String?> {
  @override
  String? build() => '@me:server';

  void set(String? userId) => state = userId;
}

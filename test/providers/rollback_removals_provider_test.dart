// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/domain/account/entities/account_boot_snapshot.dart';
import 'package:twake_chat/providers/account_boot_snapshot_provider.dart';
import 'package:twake_chat/data/account/datasources_impl/client_manager_account_data_source.provider.dart';
import 'package:twake_chat/data/account/sources/account_client_registry.provider.dart';
import 'package:twake_chat/providers/account_services_providers.dart';
import 'package:twake_chat/providers/boot_clients_provider.dart';
import 'package:twake_chat/providers/report_failure_provider.dart';
import 'package:twake_chat/data/account/rollback_removals.dart';
import 'package:twake_chat/providers/rollback_removals_provider.dart';

import '../data/account/fakes.dart';

void main() {
  late FakeAccountClientDataSource dataSource;
  late List<String> reports;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dataSource = FakeAccountClientDataSource();
    reports = [];
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        accountClientDataSourceProvider.overrideWithValue(dataSource),
        bootClientsProvider.overrideWithValue(const []),
        bootAccountSnapshotProvider.overrideWithValue(
          const AccountBootSnapshot(),
        ),
        reportFailureProvider.overrideWithValue(
          (error, stackTrace, what) => reports.add(what),
        ),
      ],
    );
  });

  test('is created once and disposed with its container', () {
    final created = container.read(rollbackRemovalsProvider);

    expect(container.read(rollbackRemovalsProvider), same(created));

    container.dispose();

    expect(
      () => container.read(rollbackRemovalsProvider),
      throwsA(isA<StateError>()),
    );
  });

  test('retries a failed discard on the same instance', () async {
    dataSource.failDelete = true;
    final created = container.read(rollbackRemovalsProvider);
    // adopt() clears the registry, so the client is added after it.
    container
        .read(accountClientRegistryProvider)
        .add(FakeAccountClient('x', userID: '@x:s'));

    await expectLater(
      created.discardCandidate('x'),
      throwsA(isA<RemovalPendingException>()),
    );
    expect(container.read(rollbackRemovalsProvider), same(created));
    expect(container.read(candidateRemovalsProvider).isPending('x'), isTrue);

    dataSource.failDelete = false;
    await created.retryRecordedDiscards();

    expect(container.read(candidateRemovalsProvider).isPending('x'), isFalse);
    expect(dataSource.calls.where((call) => call == 'delete:x'), [
      'delete:x',
      'delete:x',
    ]);
  });

  test('disposing the container stops a removal the provider started', () {
    fakeAsync((async) {
      dataSource.failDelete = true;
      final created = container.read(rollbackRemovalsProvider);
      container
          .read(accountClientRegistryProvider)
          .add(FakeAccountClient('x', userID: '@x:s'));
      var failed = false;
      created
          .discardCandidate('x')
          .then(
            (_) {},
            onError: (Object _, StackTrace _) {
              failed = true;
            },
          );
      async.flushMicrotasks();
      expect(failed, isTrue);
      expect(dataSource.calls.where((call) => call == 'delete:x'), [
        'delete:x',
      ]);

      container.dispose();
      async.elapse(const Duration(hours: 1));

      expect(dataSource.calls.where((call) => call == 'delete:x'), [
        'delete:x',
      ]);
    });
  });

  test('a discard that is pending is not started again by the session, which '
      'still sees it as pending', () async {
    dataSource.failDelete = true;
    final created = container.read(rollbackRemovalsProvider);
    container
        .read(accountClientRegistryProvider)
        .add(FakeAccountClient('x', userID: '@x:s'));
    await expectLater(
      created.discardCandidate('x'),
      throwsA(isA<RemovalPendingException>()),
    );

    await expectLater(
      created.discardCandidate('x'),
      throwsA(isA<RemovalPendingException>()),
    );

    expect(dataSource.calls.where((call) => call == 'delete:x'), ['delete:x']);
    expect(reports, hasLength(1));
  });

  test('a pending discard that the removals finished is not pending for the '
      'session any more', () async {
    dataSource.failDelete = true;
    final created = container.read(rollbackRemovalsProvider);
    container
        .read(accountClientRegistryProvider)
        .add(FakeAccountClient('x', userID: '@x:s'));
    await expectLater(
      created.discardCandidate('x'),
      throwsA(isA<RemovalPendingException>()),
    );
    dataSource.failDelete = false;
    await container.read(candidateRemovalsProvider).retryAll();

    await created.discardCandidate('x');

    expect(dataSource.calls.where((call) => call == 'delete:x'), [
      'delete:x',
      'delete:x',
    ]);
  });

  test(
    'a discard that fails is held by the candidate removals of the container '
    'and reported through the shared reporter',
    () async {
      dataSource.failDelete = true;

      await expectLater(
        container.read(rollbackRemovalsProvider).discardCandidate('x'),
        throwsA(isA<RemovalPendingException>()),
      );

      expect(container.read(candidateRemovalsProvider).isPending('x'), isTrue);
      expect(reports, isNotEmpty);
    },
  );
}

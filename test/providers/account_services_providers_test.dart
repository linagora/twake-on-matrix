// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/providers/account_services_providers.dart';
import 'package:twake_chat/data/account/logout_removals.dart';

void main() {
  test('each service is one instance for the whole container', () {
    final container = ProviderContainer.test();

    expect(
      container.read(clientSubscriptionsProvider),
      same(container.read(clientSubscriptionsProvider)),
    );
    expect(
      container.read(logoutRemovalsProvider),
      same(container.read(logoutRemovalsProvider)),
    );
    expect(
      container.read(logoutRemovalsProvider),
      isNot(same(container.read(pushRemovalsProvider))),
    );
    expect(
      container.read(quietLogoutsProvider),
      same(container.read(quietLogoutsProvider)),
    );
    expect(
      container.read(candidateRemovalsProvider),
      same(container.read(candidateRemovalsProvider)),
    );
    expect(
      container.read(candidateRemovalsProvider),
      isNot(same(container.read(logoutRemovalsProvider))),
    );
  });

  for (final entry in {
    'logout removals': logoutRemovalsProvider,
    'push removals': pushRemovalsProvider,
    'candidate removals': candidateRemovalsProvider,
  }.entries) {
    test('the ${entry.key} stop retrying when the container is disposed', () {
      fakeAsync((async) {
        final container = ProviderContainer.test();
        final removals = container.read(entry.value);
        var tries = 0;
        removals.remove(
          'a',
          RemovalSteps(
            remove: () async {
              tries++;
              throw StateError('fails');
            },
            hold: () async {},
            settle: () async {},
          ),
          (_, _, _) {},
        );
        async.flushMicrotasks();
        expect(tries, 1);

        container.dispose();
        async.elapse(const Duration(hours: 1));

        expect(tries, 1);
      });
    });
  }

  test(
    'the subscriptions are cancelled when the container is disposed',
    () async {
      final container = ProviderContainer.test();
      final subscriptions = container.read(clientSubscriptionsProvider);
      var cancelled = false;
      subscriptions
        ..open('a')
        ..keep(
          'a',
          'sync',
          () =>
              () async => cancelled = true,
        );

      container.dispose();
      await pumpEventQueue();

      expect(cancelled, isTrue);
    },
  );
}
